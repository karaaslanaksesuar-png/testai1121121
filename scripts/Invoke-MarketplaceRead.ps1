param(
    [Parameter(Mandatory)][ValidateSet('trendyol','shopier')][string]$Provider,
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$OutputPath
)
$ErrorActionPreference = 'Stop'
if ($Path -notmatch '^/(?!/)' -or $Path -match '[\r\n\\#]' -or $Path -match '(^|/)\.\.(/|$)') { throw 'A safe relative API path is required.' }
$secrets = & (Join-Path $PSScriptRoot 'Get-MarketplaceSecrets.ps1')
if ($Provider -eq 'trendyol') {
    if ($Path -notmatch '^/integration/') { throw 'Trendyol paths must begin /integration/.' }
    if (-not $secrets.TRENDYOL_SELLER_ID -or -not $secrets.TRENDYOL_BASIC_TOKEN) { throw 'Trendyol credentials not configured.' }
    $uri = 'https://apigw.trendyol.com' + $Path.Replace('{sellerId}', $secrets.TRENDYOL_SELLER_ID)
    $headers = @{Authorization = 'Basic ' + $secrets.TRENDYOL_BASIC_TOKEN; 'User-Agent' = $secrets.TRENDYOL_SELLER_ID + ' - SelfIntegration'; Accept = 'application/json'}
} else {
    if (-not $secrets.SHOPIER_TOKEN) { throw 'Shopier credentials not configured.' }
    $uri = 'https://api.shopier.com/v1' + $Path
    $headers = @{Authorization = 'Bearer ' + $secrets.SHOPIER_TOKEN; Accept = 'application/json'}
}
try { $response = Invoke-WebRequest -Uri $uri -Method GET -Headers $headers -TimeoutSec 45 }
catch {
    $status = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 'network error' }
    throw "Marketplace GET failed: $status. Credentials and response body omitted."
}
$fullPath = [IO.Path]::GetFullPath($OutputPath)
New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($fullPath)) -Force | Out-Null
[IO.File]::WriteAllText($fullPath, $response.Content, [Text.UTF8Encoding]::new($false))
Write-Output "GET successful; response saved to $fullPath. Keep merchant responses out of Git."
