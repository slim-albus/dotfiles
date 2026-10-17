# ============================================================
# Functions & Extended Utilities
# ============================================================

# Load the interactive manual 'dots'
$dotsScript = Join-Path $PSScriptRoot 'dots.ps1'
if (Test-Path -LiteralPath $dotsScript) {
    . $dotsScript
}

# ---- Network & Process Helpers ----
function port {
    param([Parameter(Mandatory)][int]$Port)
    Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue |
        Select-Object LocalAddress, LocalPort, State,
                      @{n='Process';e={ (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName }},
                      @{n='PID';e={ $_.OwningProcess }}
}

function killport {
    param([Parameter(Mandatory)][int]$Port)
    $connections = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    if (-not $connections) {
        Write-Host "No process listening on port $Port." -ForegroundColor Yellow
        return
    }
    $pids = $connections | Select-Object -ExpandProperty OwningProcess -Unique
    foreach ($processId in $pids) {
        try {
            Stop-Process -Id $processId -Force -ErrorAction Stop
            Write-Host "Stopped process ${processId} listening on port $Port." -ForegroundColor Green
        } catch {
            Write-Error "Failed to stop process ${processId}: $_"
        }
    }
}

function pkill {
    param([Parameter(Mandatory)][string]$Name)
    Get-Process -Name $Name -ErrorAction SilentlyContinue | Stop-Process -Force
}

function pgrep {
    param([Parameter(Mandatory)][string]$Name)
    Get-Process -Name "*$Name*" -ErrorAction SilentlyContinue
}

# ---- File & Archive Helpers ----
function extract {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { Write-Error "Not found: $Path"; return }
    $ext = [IO.Path]::GetExtension($Path).ToLower()
    switch ($ext) {
        '.zip' { Expand-Archive -Path $Path -DestinationPath (Split-Path $Path -Parent) -Force }
        default { Write-Host "Unsupported archive type: $ext (use 7z or tar for other formats)" -ForegroundColor Yellow }
    }
}

function trash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string[]]$Path
    )

    process {
        foreach ($target in $Path) {
            $resolved = Resolve-Path -LiteralPath $target -ErrorAction SilentlyContinue
            if (-not $resolved) {
                Write-Warning "Item not found: $target"
                continue
            }
            $fullPath = $resolved.ProviderPath
            $item = Get-Item -LiteralPath $fullPath
            $parentPath = if ($item.PSIsContainer) {
                if ($item.Parent) { $item.Parent.FullName } else { Split-Path -Path $item.FullName -Parent }
            } else {
                $item.DirectoryName
            }

            if ([string]::IsNullOrWhiteSpace($parentPath)) {
                Write-Error "Cannot move root directory to Recycle Bin: $fullPath"
                continue
            }

            try {
                $shell = New-Object -ComObject 'Shell.Application'
                $shellFolder = $shell.NameSpace($parentPath)
                $shellItem = if ($shellFolder) { $shellFolder.ParseName($item.Name) } else { $null }

                if ($shellItem) {
                    $shellItem.InvokeVerb('delete')
                    Write-Host "Moved to Recycle Bin: $fullPath" -ForegroundColor DarkGray
                } else {
                    Write-Error "Could not move to Recycle Bin: $fullPath"
                }
            } catch {
                Write-Error "Failed to recycle ${fullPath}: $_"
            }
        }
    }
}

function sed {
    param(
        [Parameter(Mandatory)][string]$File,
        [Parameter(Mandatory)][string]$Find,
        [Parameter(Mandatory)][string]$Replace
    )
    (Get-Content -LiteralPath $File).Replace($Find, $Replace) | Set-Content -LiteralPath $File
}

function which {
    param([Parameter(Mandatory)][string]$Name)
    Get-Command -Name $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

function head {
    param([Parameter(Mandatory)][string]$Path, [int]$Lines = 10)
    Get-Content -LiteralPath $Path -Head $Lines
}

function tail {
    param([Parameter(Mandatory)][string]$Path, [int]$Lines = 10, [switch]$Wait)
    Get-Content -LiteralPath $Path -Tail $Lines -Wait:$Wait
}

function Get-BigFiles {
    param([string]$Path = ".", [int]$Top = 20)
    Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object Length -Descending |
        Select-Object -First $Top FullName, @{n='MB';e={ [math]::Round($_.Length/1MB,2) }}
}

function Backup-Item {
    param([Parameter(Mandatory)][string]$Path)
    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    $destination = "$($item.FullName).$(Get-Date -Format yyyyMMdd-HHmmss).bak"
    Copy-Item -LiteralPath $item.FullName -Destination $destination -Recurse
    Write-Host "Backup created: $destination" -ForegroundColor Green
    $destination
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

# ---- Navigation & Git Workspace Helpers ----
function project-root {
    $root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and $root) { return $root }
    (Get-Location).Path
}

function croot { Set-Location (project-root) }

function up {
    param([int]$Levels = 1)
    $path = Get-Location
    1..$Levels | ForEach-Object { $path = Split-Path $path -Parent }
    Set-Location $path
}

function New-TempDirectory {
    $directory = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $directory | Out-Null
    Set-Location $directory
    $directory
}
Set-Alias mktempdir New-TempDirectory

# ---- Development Helpers ----
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
    & $env:EDITOR $PROFILE.CurrentUserCurrentHost
}
Set-Alias ep Edit-Profile

function Find-File {
    param([Parameter(Mandatory)][string]$Name, [string]$Path = ".")
    Get-ChildItem -Path $Path -Recurse -File -Filter "*$Name*" -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FullName
}
Set-Alias ff Find-File

function Reload-Profile {
    $cacheDir = Join-Path $env:LOCALAPPDATA "dotfiles-cache"
    if (Test-Path $cacheDir) {
        Remove-Item -Path "$cacheDir\*" -Force -ErrorAction SilentlyContinue
    }
    . $PROFILE
    Write-Host "PowerShell profile reloaded." -ForegroundColor Green
}
Set-Alias reload Reload-Profile

# ---- System & Admin Helpers ----
function admin {
    $cwd = (Get-Location).ProviderPath
    $shell = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { 'pwsh.exe' } else { 'powershell.exe' }
    $shellArgs = if ($args.Count -gt 0) { @('-NoExit', '-Command', ($args -join ' ')) } else { @('-NoExit') }

    if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
        Start-Process wt.exe -Verb RunAs -ArgumentList (@('-d', "`"$cwd`"", $shell) + $shellArgs)
    } else {
        Start-Process $shell -Verb RunAs -WorkingDirectory $cwd -ArgumentList $shellArgs
    }
}
Set-Alias su admin

function flushdns {
    Clear-DnsClientCache
    Write-Host 'DNS client cache has been flushed.' -ForegroundColor Green
}

function uptime {
    if (Get-Command Get-Uptime -ErrorAction SilentlyContinue) {
        Get-Uptime
    } else {
        (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    }
}

function sysinfo {
    if (Get-Command fastfetch.exe -ErrorAction SilentlyContinue) {
        fastfetch
    } else {
        Get-ComputerInfo -Property OsName, OsVersion, CsName, OsUptime -ErrorAction SilentlyContinue
        Get-PSDrive -PSProvider FileSystem | Select-Object Name, Used, Free
    }
}

function Get-Weather {
    param([string]$Location = "")
    if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
        throw 'curl is required for weather.'
    }
    curl.exe -fsSL "https://wttr.in/$Location?format=3"
}
Set-Alias weather Get-Weather

function winutil {
    & ([ScriptBlock]::Create((Invoke-RestMethod -Uri 'https://christitus.com/win'))) @args
}

function Update-PowerShell {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        Write-Warning 'winget is required to update PowerShell automatically.'
        return
    }

    try {
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest' -ErrorAction Stop
        $currentVersion = [version]$PSVersionTable.PSVersion
        $latestVersion = [version]($release.tag_name -replace '^v', '')

        if ($currentVersion -ge $latestVersion) {
            Write-Host "PowerShell $currentVersion is up to date." -ForegroundColor Green
            return
        }

        if ($PSCmdlet.ShouldProcess("PowerShell $currentVersion", "Upgrade to $latestVersion")) {
            winget upgrade --id Microsoft.PowerShell --exact --accept-source-agreements --accept-package-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-Host 'PowerShell updated. Restart your shell to use the new version.' -ForegroundColor Green
            } else {
                Write-Error "winget failed to update PowerShell. Exit code: $LASTEXITCODE"
            }
        }
    } catch {
        Write-Error "Failed to check PowerShell updates: $_"
    }
}

function Invoke-DotfilesDoctor {
    Write-Host "`n  Dotfiles Health Check" -ForegroundColor Cyan
    Write-Host ("  " + ("=" * 50)) -ForegroundColor DarkGray

    $tools = @('git', 'pwsh', 'bun', 'starship', 'zoxide', 'micro', 'fastfetch', 'winget')
    foreach ($tool in $tools) {
        $cmd = Get-Command "$tool.exe" -ErrorAction SilentlyContinue
        if ($cmd) {
            $ver = try { & $tool.exe --version 2>$null | Select-Object -First 1 } catch { "Found" }
            Write-Host "  [ OK ] " -ForegroundColor Green -NoNewline
            Write-Host ("{0,-12}" -f $tool) -ForegroundColor Yellow -NoNewline
            Write-Host ": $($cmd.Source) ($ver)" -ForegroundColor DarkGray
        } else {
            Write-Host "  [MISS] " -ForegroundColor Red -NoNewline
            Write-Host ("{0,-12}" -f $tool) -ForegroundColor Yellow -NoNewline
            Write-Host ": Not found in PATH" -ForegroundColor DarkGray
        }
    }

    # Profile Linkage Check
    Write-Host "`n  Profile Configuration:" -ForegroundColor Cyan
    $profileTarget = $PROFILE.CurrentUserCurrentHost
    if (Test-Path -LiteralPath $profileTarget) {
        $content = Get-Content -LiteralPath $profileTarget -Raw -ErrorAction SilentlyContinue
        if ($content -match "Microsoft\.PowerShell_profile\.ps1") {
            Write-Host "  [ OK ] Profile Loader active at: $profileTarget" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] Profile exists but doesn't appear to source dotfiles: $profileTarget" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [MISS] Profile does not exist yet at: $profileTarget" -ForegroundColor Red
    }
    Write-Host ""
}