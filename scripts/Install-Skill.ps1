param([string]$SkillRoot)
$ErrorActionPreference = 'Stop'
if (-not $SkillRoot) {
    $codexRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex' }
    $SkillRoot = Join-Path $codexRoot 'skills'
}
$source = Join-Path (Split-Path $PSScriptRoot -Parent) 'skills/marketplace-operations'
$destination = Join-Path $SkillRoot 'marketplace-operations'
if (Test-Path -LiteralPath $destination) { throw 'Skill already exists. Inspect differences before updating.' }
New-Item -ItemType Directory -Path $SkillRoot -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $destination -Recurse
Write-Output 'marketplace-operations skill installed. Start a new Codex conversation to discover it.'
