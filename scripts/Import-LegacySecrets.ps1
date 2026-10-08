param([string]$DesktopPath = [Environment]::GetFolderPath('Desktop'))
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'This encrypted vault uses Windows user/machine protection.' }
$projectRoot = Split-Path $PSScriptRoot -Parent
$vaultPath = Join-Path $projectRoot '.secrets/credentials.clixml'
$vault = if (Test-Path -LiteralPath $vaultPath) { Import-Clixml -LiteralPath $vaultPath } else { @{} }
$tyFile = Join-Path $DesktopPath 'apikey-trendyol.txt'
if (Test-Path -LiteralPath $tyFile) {
    $lines = @(Get-Content -LiteralPath $tyFile)
    if ($lines.Count -lt 13 -or $lines[4].Trim() -notmatch '^\d+$') { throw 'Legacy Trendyol layout invalid.' }
    $token = $lines[12].Trim()
    if (-not ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($token))).Contains(':')) { throw 'Invalid Trendyol Basic token.' }
    $vault['TRENDYOL_SELLER_ID'] = ConvertTo-SecureString $lines[4].Trim() -AsPlainText -Force
    $vault['TRENDYOL_BASIC_TOKEN'] = ConvertTo-SecureString $token -AsPlainText -Force
}
$shopFile = Join-Path $DesktopPath 'shopier-key.txt'
if (Test-Path -LiteralPath $shopFile) {
    $shopToken = (Get-Content -LiteralPath $shopFile -Raw).Trim()
    if (-not $shopToken -or $shopToken -match '\s') { throw 'Unexpected Shopier token format.' }
    $vault['SHOPIER_TOKEN'] = ConvertTo-SecureString $shopToken -AsPlainText -Force
}
if ($vault.Count -eq 0) { throw 'No known credentials found.' }
New-Item -ItemType Directory -Path (Split-Path $vaultPath -Parent) -Force | Out-Null
$vault | Export-Clixml -LiteralPath $vaultPath
Write-Output ('Encrypted local credentials saved: ' + ($vault.Keys -join ', ') + '. Values were not printed. Vault is bound to this Windows user/computer.')
