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

function New-TempDirectory {
    $directory = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $directory | Out-Null
    Set-Location $directory
    $directory
}

function Show-ProcessMatch {
    param([Parameter(Mandatory)][string]$Name)
    Get-Process | Where-Object ProcessName -Match $Name
}

function Get-SystemInfo {
    Get-ComputerInfo -Property OsName, OsVersion, CsName, OsUptime -ErrorAction SilentlyContinue
    Get-PSDrive -PSProvider FileSystem | Select-Object Name, Used, Free
}

function Get-Weather {
    param([string]$Location = "")
    if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
        throw 'curl is required for weather.'
    }
    curl.exe -fsSL "https://wttr.in/$Location?format=3"
}

function Backup-Item {
    param([Parameter(Mandatory)][string]$Path)
    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    $destination = "$($item.FullName).$(Get-Date -Format yyyyMMdd-HHmmss).bak"
    Copy-Item -LiteralPath $item.FullName -Destination $destination -Recurse
    $destination
}

function Invoke-DotfilesDoctor {
    $failed = $false
    Write-Host 'Dotfiles doctor'
    foreach ($command in @('git', 'pwsh')) {
        if (Get-Command $command -ErrorAction SilentlyContinue) {
            Write-Host "OK   command: $command"
        } else {
            Write-Host "MISS command: $command"
            $failed = $true
        }
    }
    $profileLine = ". `"$PSScriptRoot\Microsoft.PowerShell_profile.ps1`""
    if (Select-String -Path $PROFILE.CurrentUserAllHosts -SimpleMatch $profileLine -Quiet -ErrorAction SilentlyContinue) {
        Write-Host 'OK   PowerShell startup'
    } else {
        Write-Host 'MISS PowerShell startup'
        $failed = $true
    }
    if ($failed) { return 1 }
    return 0
}

function Show-Tree {
    param([string]$Path = ".", [string]$OutputFile)
    $root = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $root -or -not $root.PSIsContainer) {
        Write-Error "Not a directory: $Path"
        return
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add($root.Name)
    $walk = {
        param([string]$CurrentPath, [string]$Prefix)
        $children = @(Get-ChildItem -LiteralPath $CurrentPath -Force -ErrorAction SilentlyContinue |
            Sort-Object @{Expression={ -not $_.PSIsContainer }}, Name)
        for ($index = 0; $index -lt $children.Count; $index++) {
            $child = $children[$index]
            $isLast = $index -eq ($children.Count - 1)
            $branch = if ($isLast) { '\-- ' } else { '|-- ' }
            $lines.Add("$Prefix$branch$($child.Name)")
            if ($child.PSIsContainer) {
                $nextPrefix = if ($isLast) { "$Prefix    " } else { "$Prefix|   " }
                & $walk $child.FullName $nextPrefix
            }
        }
    }
    & $walk $root.FullName ""

    if ($OutputFile) {
        $lines | Set-Content -LiteralPath $OutputFile
    } else {
        $lines
    }
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

function Edit-Profile {
    & $env:EDITOR $PROFILE.CurrentUserAllHosts
}
Set-Alias ep Edit-Profile

function Find-File {
    param([Parameter(Mandatory)][string]$Name, [string]$Path = ".")
    Get-ChildItem -Path $Path -Recurse -File -Filter "*$Name*" -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FullName
}
Set-Alias ff Find-File

function head {
    param([Parameter(Mandatory)][string]$Path, [int]$Lines = 10)
    Get-Content -Path $Path -Head $Lines
}

function tail {
    param([Parameter(Mandatory)][string]$Path, [int]$Lines = 10, [switch]$Follow)
    Get-Content -Path $Path -Tail $Lines -Wait:$Follow
}

function uptime {
    if (Get-Command Get-Uptime -ErrorAction SilentlyContinue) {
        Get-Uptime
    } else {
        (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    }
}

function cpy { Set-Clipboard ($args -join ' ') }
function pst { Get-Clipboard }

function Show-ProfileHelp {
    @'
PowerShell profile commands:
  ep                 Edit the current PowerShell profile
  reload             Reload the profile
  ff NAME [PATH]     Find files recursively by name
    Show-Tree [PATH] [OUTPUT_FILE]
    Invoke-DotfilesDoctor  Check the PowerShell setup
  head FILE [N]      Show the first N lines
  tail FILE [N]      Show the last N lines
  uptime             Show system uptime
  cpy TEXT           Copy text to the clipboard
  pst                Read clipboard text
'@ | Write-Host
}
Set-Alias profile-help Show-ProfileHelp