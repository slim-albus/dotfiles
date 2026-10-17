[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Minimal,
    [switch]$Force,
    [string]$LogFile
)

$ErrorActionPreference = 'Continue'

if ($LogFile) {
    $logDir = Split-Path -Path $LogFile -Parent
    if ($logDir -and -not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Start-Transcript -Path $LogFile -Append | Out-Null
}

function Write-Status {
    param(
        [Parameter(Mandatory)][ValidateSet('OK', 'SKIP', 'WARN', 'FAIL', 'INFO', 'DRY-RUN')]
        [string]$Status,
        [Parameter(Mandatory)][string]$Message
    )
    $color = switch ($Status) {
        'OK'      { 'Green' }
        'SKIP'    { 'Cyan' }
        'WARN'    { 'Yellow' }
        'FAIL'    { 'Red' }
        'INFO'    { 'DarkCyan' }
        'DRY-RUN' { 'Magenta' }
    }
    $badge = "[{0,4}]" -f $Status
    Write-Host "  $badge " -ForegroundColor $color -NoNewline
    Write-Host $Message -ForegroundColor White
}

# Known executable mapping to rapidly skip already-installed packages
$commandMap = @{
    'Git.Git'                 = 'git.exe'
    'zyedidia.micro'          = 'micro.exe'
    'Starship.Starship'       = 'starship.exe'
    'ajeetdsouza.zoxide'      = 'zoxide.exe'
    'junegunn.fzf'            = 'fzf.exe'
    'sxyazi.yazi'             = 'yazi.exe'
    'BurntSushi.ripgrep.MSVC' = 'rg.exe'
    'sharkdp.fd'              = 'fd.exe'
    'sharkdp.bat'             = 'bat.exe'
    'dandavison.delta'        = 'delta.exe'
    'aristocratos.btop4win'   = 'btop.exe'
    'direnv.direnv'           = 'direnv.exe'
    'jqlang.jq'               = 'jq.exe'
    '7zip.7zip'               = '7z.exe'
    'cURL.cURL'               = 'curl.exe'
    'GNU.Wget2'               = 'wget2.exe'
    'eza-community.eza'       = 'eza.exe'
}

$packageFile = Join-Path $PSScriptRoot '..\packages\winget.txt'
if (-not (Test-Path -LiteralPath $packageFile)) {
    Write-Status -Status 'FAIL' -Message "Package list not found at: $packageFile"
    exit 1
}

$rawPackages = Get-Content -LiteralPath $packageFile |
    ForEach-Object { ($_ -replace '#.*$', '').Trim() } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

if (-not $rawPackages -or $rawPackages.Count -eq 0) {
    Write-Status -Status 'FAIL' -Message "Package list is empty: $packageFile"
    exit 1
}

$packages = if ($Minimal) {
    $rawPackages | Where-Object { $_ -in @('Git.Git', 'zyedidia.micro', 'Starship.Starship') }
} else {
    $rawPackages
}

Write-Host "`n  ========================================================" -ForegroundColor Cyan
Write-Host "             Dotfiles Winget Package Installer            " -ForegroundColor Cyan
Write-Host "  ========================================================" -ForegroundColor Cyan
Write-Host "  Package Manifest: $packageFile" -ForegroundColor DarkGray
Write-Host "  Total Packages  : $($packages.Count)" -ForegroundColor DarkGray
if ($Minimal) { Write-Host "  Profile Mode    : MINIMAL" -ForegroundColor Yellow }
if ($DryRun)  { Write-Host "  Execution Mode  : PREVIEW ONLY (-DryRun)" -ForegroundColor Magenta }

if (-not $DryRun -and -not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    Write-Status -Status 'FAIL' -Message "winget was not found. Please install App Installer from Microsoft Store."
    exit 1
}

$totalCount     = $packages.Count
$installedCount = 0
$skippedCount   = 0
$failedCount    = 0
$failedPackages = [System.Collections.Generic.List[string]]::new()

$currentIndex = 0
foreach ($package in $packages) {
    $currentIndex++
    $counter = "[{0,2}/{1,2}]" -f $currentIndex, $totalCount

    # Fast Pre-flight Check
    $exeName = $commandMap[$package]
    $alreadyInstalled = $false
    if ($exeName -and -not $Force) {
        if (Get-Command $exeName -ErrorAction SilentlyContinue) {
            $alreadyInstalled = $true
        }
    }

    if ($alreadyInstalled) {
        Write-Status -Status 'SKIP' -Message "$counter Already present: $package ($exeName found in PATH)"
        $skippedCount++
        continue
    }

    $wingetArgs = @(
        'install',
        '--id', $package,
        '--exact',
        '--source', 'winget',
        '--accept-source-agreements',
        '--accept-package-agreements'
    )

    if ($DryRun) {
        Write-Status -Status 'DRY-RUN' -Message "$counter winget $($wingetArgs -join ' ')"
        $skippedCount++
        continue
    }

    Write-Status -Status 'INFO' -Message "$counter Installing $package ..."
    & winget @wingetArgs

    # Exit code 0 is success; 0x8A15002B (-1978335189) is already installed
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
        Write-Status -Status 'OK' -Message "$counter Successfully installed: $package"
        $installedCount++
    } else {
        Write-Status -Status 'FAIL' -Message "$counter Failed to install: $package (ExitCode: $LASTEXITCODE)"
        $failedCount++
        $failedPackages.Add("$package (Exit code: $LASTEXITCODE)")
    }
}

# ------------------------------------------------------------
# Summary Report
# ------------------------------------------------------------
Write-Host "`n  ========================================================" -ForegroundColor Cyan
Write-Host "                Package Installation Summary              " -ForegroundColor Cyan
Write-Host "  ========================================================" -ForegroundColor Cyan
Write-Host "  Total In Queue   : $totalCount" -ForegroundColor White
Write-Host "  Installed        : $installedCount" -ForegroundColor Green
Write-Host "  Skipped (Present): $skippedCount" -ForegroundColor Cyan
Write-Host "  Failed           : $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { 'Red' } else { 'Green' })

if ($failedCount -gt 0) {
    Write-Host "`n  Failed Packages:" -ForegroundColor Red
    foreach ($failed in $failedPackages) {
        Write-Host "    - $failed" -ForegroundColor Red
    }
    Write-Host "`n  Tip: You can retry failed packages individually with: winget install --id <package>" -ForegroundColor DarkGray
}

Write-Host "  ========================================================`n" -ForegroundColor Cyan

if ($LogFile) {
    Stop-Transcript | Out-Null
}