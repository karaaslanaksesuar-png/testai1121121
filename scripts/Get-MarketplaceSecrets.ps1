param([string]$VaultPath = (Join-Path (Split-Path $PSScriptRoot -Parent) '.secrets/credentials.clixml'))
$ErrorActionPreference = 'Stop'
$result = @{}
if (Test-Path -LiteralPath $VaultPath) {
    $vault = Import-Clixml -LiteralPath $VaultPath
    foreach ($name in $vault.Keys) {
        $result[$name] = [System.Net.NetworkCredential]::new('', $vault[$name]).Password
    }
}
foreach ($name in @('TRENDYOL_SELLER_ID','TRENDYOL_BASIC_TOKEN','SHOPIER_TOKEN','HEPSIBURADA_SERVICE_KEY')) {
    $value = [Environment]::GetEnvironmentVariable($name)
    if ($value) { $result[$name] = $value }
}
# Return only to the calling script. Do not invoke this helper standalone in a shared transcript.
return $result
