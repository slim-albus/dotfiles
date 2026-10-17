# ============================================================
# Environment variables & Path configuration
# ============================================================

# Default editor & pager
if (-not $env:EDITOR) { $env:EDITOR = "micro" }
if (-not $env:PAGER)  { $env:PAGER  = "less" }

# Tell Starship where its configuration lives
$dotfilesRoot = if ($global:DotfilesRoot) { $global:DotfilesRoot } else { Split-Path -Parent $PSScriptRoot }
$env:STARSHIP_CONFIG = Join-Path $dotfilesRoot "shared\starship.toml"

# ---- Fast PATH Prepending ----
$pathEntries = @(
    "$HOME\.bun\bin",
    "$HOME\.local\bin",
    "$HOME\.cargo\bin",
    "$HOME\go\bin",
    "$HOME\scoop\shims",
    "$env:USERPROFILE\bin"
)

$currentPaths = $env:Path -split [IO.Path]::PathSeparator
$newPaths = [System.Collections.Generic.List[string]]::new()

foreach ($entry in $pathEntries) {
    if ((Test-Path -LiteralPath $entry) -and ($currentPaths -notcontains $entry)) {
        $newPaths.Add($entry)
    }
}

if ($newPaths.Count -gt 0) {
    $env:Path = ($newPaths + $currentPaths) -join [IO.Path]::PathSeparator
}

# ---- Tool Initializers (Cached for Sub-150ms Startup) ----
$cacheDir = Join-Path $env:LOCALAPPDATA "dotfiles-cache"
if (-not (Test-Path -LiteralPath $cacheDir)) {
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
}

# Zoxide initialization
$zoxideBin = Get-Command zoxide.exe -ErrorAction SilentlyContinue
if ($zoxideBin) {
    $zoxideCache = Join-Path $cacheDir "zoxide_init.ps1"
    $needGen = $true
    if (Test-Path -LiteralPath $zoxideCache) {
        $cacheItem = Get-Item -LiteralPath $zoxideCache
        $binItem = Get-Item -LiteralPath $zoxideBin.Source
        if ($cacheItem.LastWriteTime -ge $binItem.LastWriteTime) {
            $needGen = $false
        }
    }
    if ($needGen) {
        try {
            & $zoxideBin.Source init --cmd z powershell | Out-File -FilePath $zoxideCache -Encoding utf8
        } catch {}
    }
    if (Test-Path -LiteralPath $zoxideCache) {
        . $zoxideCache
    }
}

# Direnv initialization
$direnvBin = Get-Command direnv.exe -ErrorAction SilentlyContinue
if ($direnvBin) {
    # Ensure standard config directory exists so direnv does not error
    $xdgConfig = Join-Path $env:USERPROFILE ".config"
    if (-not (Test-Path -LiteralPath $xdgConfig)) {
        New-Item -ItemType Directory -Path $xdgConfig -Force | Out-Null
    }
    if (-not $env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME = $xdgConfig }

    $direnvConfigDir = Join-Path $xdgConfig "direnv"
    if (-not (Test-Path -LiteralPath $direnvConfigDir)) {
        New-Item -ItemType Directory -Path $direnvConfigDir -Force | Out-Null
    }
    if (-not $env:DIRENV_CONFIG) { $env:DIRENV_CONFIG = $direnvConfigDir }

    $direnvCache = Join-Path $cacheDir "direnv_init.ps1"
    $needGen = $true
    if (Test-Path -LiteralPath $direnvCache) {
        $cacheItem = Get-Item -LiteralPath $direnvCache
        $binItem = Get-Item -LiteralPath $direnvBin.Source
        if ($cacheItem.LastWriteTime -ge $binItem.LastWriteTime) {
            $needGen = $false
        }
    }
    if ($needGen) {
        try {
            & $direnvBin.Source hook pwsh 2>$null | Out-File -FilePath $direnvCache -Encoding utf8
        } catch {}
    }
    if (Test-Path -LiteralPath $direnvCache) {
        . $direnvCache
    }
}