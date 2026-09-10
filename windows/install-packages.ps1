[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Keep package IDs editable without changing installer logic.
$packageFile = Join-Path $PSScriptRoot '..\packages\winget.txt'
if (-not (Test-Path $packageFile)) {
    throw "Package list not found: $packageFile"
}

$packages = Get-Content $packageFile |
    ForEach-Object { ($_ -replace '#.*$', '').Trim() } |
    Where-Object { $_ }

if (-not $packages) {
    throw "Package list is empty: $packageFile"
}

if (-not $DryRun -and -not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget was not found. Install App Installer from the Microsoft Store first.'
}

foreach ($package in $packages) {
    # Agreement flags keep this script non-interactive in setup automation.
    $arguments = @(
        'install'
        '--id'
        $package
        '--exact'
        '--source'
        'winget'
        '--accept-source-agreements'
        '--accept-package-agreements'
    )

    if ($DryRun) {
        Write-Host "dry-run: winget $($arguments -join ' ')"
    } else {
        & winget @arguments
        if ($LASTEXITCODE -ne 0) {
            throw "winget failed for $package with exit code $LASTEXITCODE"
        }
    }
}

Write-Host 'Packages installed with winget.'