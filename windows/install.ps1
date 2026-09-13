[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$LogFile
)

$ErrorActionPreference = 'Stop'
if ($LogFile) {
    Start-Transcript -Path $LogFile -Append | Out-Null
}
$DotfilesRoot = Split-Path -Parent $PSScriptRoot
$ProfilePath = $PROFILE.CurrentUserAllHosts
$SourceLine = ". `"$DotfilesRoot\windows\Microsoft.PowerShell_profile.ps1`""
$GitConfigPath = Join-Path $DotfilesRoot 'shared\git\config'
$GitIgnorePath = Join-Path $DotfilesRoot 'shared\git\ignore'

function Invoke-InstallStep {
    param([scriptblock]$Action, [string]$Description)
    if ($DryRun) {
        Write-Host "dry-run: $Description"
    } else {
        & $Action
        Write-Host $Description
    }
}

$profileDirectory = Split-Path -Parent $ProfilePath
Invoke-InstallStep { New-Item -ItemType Directory -Force -Path $profileDirectory | Out-Null } "created $profileDirectory"

if (-not (Test-Path $ProfilePath)) {
    Invoke-InstallStep { New-Item -ItemType File -Force -Path $ProfilePath | Out-Null } "created $ProfilePath"
}

if ((-not (Test-Path $ProfilePath)) -or
    -not (Select-String -Path $ProfilePath -SimpleMatch $SourceLine -Quiet -ErrorAction SilentlyContinue)) {
    Invoke-InstallStep { Add-Content -Path $ProfilePath -Value "`n# dotfiles: load PowerShell configuration`n$SourceLine" } "configured $ProfilePath"
}

if (Get-Command git -ErrorAction SilentlyContinue) {
    Invoke-InstallStep { git config --global --add include.path $GitConfigPath } "included shared Git config"
    Invoke-InstallStep { git config --global core.excludesFile $GitIgnorePath } "configured shared Git ignore"
}

Write-Host "PowerShell dotfiles installed from $DotfilesRoot"
if ($LogFile) {
    Stop-Transcript | Out-Null
}