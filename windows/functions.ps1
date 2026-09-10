# ============================================================
# Functions
# ============================================================

# Network helpers
function port {
    param([Parameter(Mandatory)][int]$Port)
    Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
        Select-Object LocalAddress, LocalPort, State,
                      @{n='Process';e={ (Get-Process -Id $_.OwningProcess).ProcessName }}
}

# Archive and profile helpers
# Extract any archive Windows can handle
function extract {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { Write-Error "Not found: $Path"; return }
    $ext = [IO.Path]::GetExtension($Path).ToLower()
    switch ($ext) {
        '.zip' { Expand-Archive -Path $Path -DestinationPath (Split-Path $Path -Parent) }
        default { Write-Host "Unsupported archive type: $ext" -ForegroundColor Yellow }
    }
}
    # File and project helpers

# Reload the profile
function Reload-Profile {
    . $PROFILE
    Write-Host "Profile reloaded." -ForegroundColor Green
}
Set-Alias reload Reload-Profile

# List files by size, descending
function Get-BigFiles {
    param([string]$Path = ".", [int]$Top = 20)
    Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object Length -Descending |
        Select-Object -First $Top FullName, @{n='MB';e={ [math]::Round($_.Length/1MB,2) }}
}

function killport {
    param([Parameter(Mandatory)][int]$Port)
    $connections = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    if (-not $connections) { Write-Host "Nothing is listening on port $Port."; return }
    $connections | Select-Object -ExpandProperty OwningProcess -Unique |
        Stop-Process -Force
    Write-Host "Stopped process(es) on port $Port."
}

function project-root {
    $root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0) { return $root }
    (Get-Location).Path
}

function croot { Set-Location (project-root) }

function up {
    param([int]$Levels = 1)
    $path = Get-Location
    1..$Levels | ForEach-Object { $path = Split-Path $path -Parent }
    Set-Location $path
}

function serve {
    param([string]$Path = ".", [int]$Port = 8000)
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Push-Location $Path
        try { python -m http.server $Port } finally { Pop-Location }
    } else { Write-Error 'Python is required for serve.' }
}

function json {
    param([Parameter(Mandatory)][string]$Path)
    Get-Content $Path -Raw | ConvertFrom-Json | ConvertTo-Json -Depth 100
}

function venv {
    param([string]$Path = ".venv")
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) { throw 'Python is required for venv.' }
    python -m venv $Path
    & (Join-Path $Path 'Scripts\Activate.ps1')
}

function Show-Path {
    $env:Path -split [IO.Path]::PathSeparator
}