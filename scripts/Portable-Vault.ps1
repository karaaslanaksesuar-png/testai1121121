#requires -Version 7.4
param(
    [ValidateSet('Export','Import','Test')][string]$Mode = 'Export',
    [string]$PackagePath = (Join-Path (Split-Path $PSScriptRoot -Parent) '.secrets/marketplace-transfer.mpvault'),
    [string]$VaultPath = (Join-Path (Split-Path $PSScriptRoot -Parent) '.secrets/credentials.clixml'),
    [switch]$Gui
)
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Import/export of the local vault requires Windows.' }
Add-Type -TypeDefinition @'
using System;
using System.Security.Cryptography;
using System.Text;
public static class MarketplaceVaultCrypto {
    public static byte[] Seal(byte[] plain, string password) {
        byte[] salt = RandomNumberGenerator.GetBytes(32);
        byte[] nonce = RandomNumberGenerator.GetBytes(12);
        byte[] key = Rfc2898DeriveBytes.Pbkdf2(password, salt, 600000, HashAlgorithmName.SHA256, 32);
        byte[] cipher = new byte[plain.Length]; byte[] tag = new byte[16];
        byte[] header = Encoding.ASCII.GetBytes("MPVAULT1");
        try {
            using (var aes = new AesGcm(key, 16)) aes.Encrypt(nonce, plain, cipher, tag, header);
            byte[] result = new byte[68 + cipher.Length];
            Buffer.BlockCopy(header,0,result,0,8); Buffer.BlockCopy(salt,0,result,8,32);
            Buffer.BlockCopy(nonce,0,result,40,12); Buffer.BlockCopy(tag,0,result,52,16);
            Buffer.BlockCopy(cipher,0,result,68,cipher.Length); return result;
        } finally { CryptographicOperations.ZeroMemory(key); }
    }
    public static byte[] Open(byte[] data, string password) {
        if (data.Length < 69 || data.Length > 1048576 || Encoding.ASCII.GetString(data,0,8) != "MPVAULT1")
            throw new FormatException("Invalid vault format.");
        byte[] salt = data.AsSpan(8,32).ToArray(); byte[] nonce = data.AsSpan(40,12).ToArray();
        byte[] tag = data.AsSpan(52,16).ToArray(); byte[] cipher = data.AsSpan(68).ToArray();
        byte[] key = Rfc2898DeriveBytes.Pbkdf2(password,salt,600000,HashAlgorithmName.SHA256,32);
        byte[] plain = new byte[cipher.Length];
        try {
            using (var aes = new AesGcm(key,16)) aes.Decrypt(nonce,cipher,tag,plain,data.AsSpan(0,8));
            return plain;
        } catch { CryptographicOperations.ZeroMemory(plain); throw; }
        finally { CryptographicOperations.ZeroMemory(key); }
    }
}
'@
function Read-VaultPassword {
    param([string]$Prompt)
    if (-not $Gui) { return Read-Host $Prompt -AsSecureString }
    Add-Type -AssemblyName System.Windows.Forms
    $form = [Windows.Forms.Form]::new()
    $form.Text = 'Pazaryeri sifreli anahtar paketi'
    $form.Width = 540; $form.Height = 190
    $form.StartPosition = 'CenterScreen'
    $label = [Windows.Forms.Label]::new()
    $label.Text = $Prompt + ' (en az 16 karakter; sohbete yazmayin)'
    $label.Left = 15; $label.Top = 15; $label.Width = 500; $label.Height = 40
    $box = [Windows.Forms.TextBox]::new()
    $box.Left = 15; $box.Top = 60; $box.Width = 490; $box.UseSystemPasswordChar = $true
    $ok = [Windows.Forms.Button]::new()
    $ok.Text = 'Devam'; $ok.Left = 400; $ok.Top = 100
    $ok.DialogResult = [Windows.Forms.DialogResult]::OK
    $form.Controls.AddRange(@($label,$box,$ok)); $form.AcceptButton = $ok
    try {
        if ($form.ShowDialog() -ne [Windows.Forms.DialogResult]::OK) { throw 'Cancelled by user.' }
        return ConvertTo-SecureString $box.Text -AsPlainText -Force
    } finally { $box.Clear(); $form.Dispose() }
}
try {
    if ($Mode -eq 'Test') {
        $testPassword = [Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
        $plain = [Text.Encoding]::UTF8.GetBytes('{"sample":"synthetic-not-a-real-key"}')
        $a = [MarketplaceVaultCrypto]::Seal($plain,$testPassword)
        $b = [MarketplaceVaultCrypto]::Seal($plain,$testPassword)
        $decoded = [MarketplaceVaultCrypto]::Open($a,$testPassword)
        if ([Convert]::ToBase64String($plain) -ne [Convert]::ToBase64String($decoded)) { throw 'Round-trip failed.' }
        if ([Convert]::ToBase64String($a) -eq [Convert]::ToBase64String($b)) { throw 'Randomization failed.' }
        $wrongRejected = $false
        try { [MarketplaceVaultCrypto]::Open($a,'incorrect-password') | Out-Null } catch { $wrongRejected = $true }
        $a[$a.Length-1] = $a[$a.Length-1] -bxor 1
        $tamperRejected = $false
        try { [MarketplaceVaultCrypto]::Open($a,$testPassword) | Out-Null } catch { $tamperRejected = $true }
        if (-not $wrongRejected -or -not $tamperRejected) { throw 'Authentication test failed.' }
        Write-Output 'PASS: synthetic round-trip, random salt/nonce, wrong password and tampering rejection.'
        return
    }
    $PackagePath = [IO.Path]::GetFullPath($PackagePath)
    $VaultPath = [IO.Path]::GetFullPath($VaultPath)
    if ($Mode -eq 'Export' -and (Test-Path -LiteralPath $PackagePath)) { throw 'Package already exists; choose a new path.' }
    if ($Mode -eq 'Import' -and (Test-Path -LiteralPath $VaultPath)) { throw 'Local vault exists; do not overwrite it. Choose another VaultPath and review first.' }
    if ($Mode -eq 'Export') {
        if (-not (Test-Path -LiteralPath $VaultPath)) { throw 'Local encrypted credentials vault not found.' }
        $source = Import-Clixml -LiteralPath $VaultPath
        $secrets = @{}
        foreach ($name in @('TRENDYOL_SELLER_ID','TRENDYOL_BASIC_TOKEN','SHOPIER_TOKEN','HEPSIBURADA_SERVICE_KEY')) {
            if ($source.ContainsKey($name)) { $secrets[$name] = [Net.NetworkCredential]::new('', $source[$name]).Password }
        }
        if ($secrets.Count -eq 0) { throw 'No supported secrets in vault.' }
        $securePassword = Read-VaultPassword 'Paket icin yeni parola'
        $password = [Net.NetworkCredential]::new('', $securePassword).Password
        if ($password.Length -lt 16) { throw 'Password must contain at least 16 characters. Prefer a long unique passphrase.' }
        $confirmation = Read-VaultPassword 'Ayni parolayi tekrar girin'
        if ($password -cne [Net.NetworkCredential]::new('', $confirmation).Password) { throw 'Passwords do not match.' }
        $plain = [Text.Encoding]::UTF8.GetBytes(($secrets | ConvertTo-Json -Compress))
        $package = [MarketplaceVaultCrypto]::Seal($plain,$password)
        # Verify the actual encrypted bytes before writing; do not log secret values.
        $decoded = [MarketplaceVaultCrypto]::Open($package,$password)
        if ([Convert]::ToBase64String($plain) -ne [Convert]::ToBase64String($decoded)) { throw 'Verification failed.' }
        New-Item -ItemType Directory -Path (Split-Path $PackagePath -Parent) -Force | Out-Null
        [IO.File]::WriteAllBytes($PackagePath,$package)
        $message = "Paket hazir: $PackagePath`nParolayi ayri tutun. Paketi USB veya guvenli dosya aktarimiyla diger PC'ye tasiyin. GitHub'a yuklemeyin."
    } else {
        $securePassword = Read-VaultPassword 'Paket parolasi'
        $password = [Net.NetworkCredential]::new('', $securePassword).Password
        $fileInfo = Get-Item -LiteralPath $PackagePath
        if ($fileInfo.Length -gt 1048576) { throw 'Package too large.' }
        try { $plain = [MarketplaceVaultCrypto]::Open([IO.File]::ReadAllBytes($PackagePath),$password) }
        catch { throw 'Wrong password or damaged/invalid package. No local vault was created.' }
        $secrets = [Text.Encoding]::UTF8.GetString($plain) | ConvertFrom-Json -AsHashtable
        $vault = @{}
        foreach ($name in $secrets.Keys) {
            if ($name -notin @('TRENDYOL_SELLER_ID','TRENDYOL_BASIC_TOKEN','SHOPIER_TOKEN','HEPSIBURADA_SERVICE_KEY') -or $secrets[$name] -isnot [string]) { throw 'Unexpected credential entry.' }
            $vault[$name] = ConvertTo-SecureString $secrets[$name] -AsPlainText -Force
        }
        if ($vault.Count -eq 0) { throw 'Empty vault.' }
        New-Item -ItemType Directory -Path (Split-Path $VaultPath -Parent) -Force | Out-Null
        $vault | Export-Clixml -LiteralPath $VaultPath
        $message = "Anahtarlar bu PC'nin sifreli kasasina alindi: $VaultPath`nAPI okuma testiyle baglantiyi dogrulayin."
    }
    if ($Gui) { [Windows.Forms.MessageBox]::Show($message,'Pazaryeri anahtarlari') | Out-Null }
    else { Write-Output $message }
} catch {
    if ($Gui) {
        Add-Type -AssemblyName System.Windows.Forms
        [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Islem tamamlanamadi') | Out-Null
    } else { throw }
} finally {
    if ($plain) { [Security.Cryptography.CryptographicOperations]::ZeroMemory($plain) }
    if ($decoded) { [Security.Cryptography.CryptographicOperations]::ZeroMemory($decoded) }
    $password = $null; $secrets = $null; $source = $null
    if ($securePassword) { $securePassword.Dispose() }
    if ($confirmation) { $confirmation.Dispose() }
}
