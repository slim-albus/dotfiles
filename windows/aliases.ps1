# ============================================================
# Aliases & Core Shortcuts
# ============================================================

# ---- Directory Navigation ----
function ..    { Set-Location .. }
function ...   { Set-Location ..\.. }
function ....  { Set-Location ..\..\.. }
function ~     { Set-Location $HOME }
function docs  { Set-Location ([Environment]::GetFolderPath('MyDocuments')) }
function dtop  { Set-Location ([Environment]::GetFolderPath('Desktop')) }

# ---- Listing ----
# Use eza if installed, else fallback to Get-ChildItem
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ll { eza -la --icons --git @args }
    function l  { eza -l  --icons --git @args }
    function la { eza -a  --icons @args }
    function ls { eza     --icons @args }
} else {
    function ll { Get-ChildItem -Force @args }
    function l  { Get-ChildItem @args }
    function la { Get-ChildItem -Force @args }
    Set-Alias ls Get-ChildItem -Option AllScope
}

# ---- Git Shortcuts ----
function gs    { git status @args }
function ga    { git add @args }
function gc    { git commit @args }
function gp    { git push @args }
function gpull { git pull @args }
function gl    { git log --oneline --graph --decorate -20 @args }
function gd    { git diff @args }
function gco   { git checkout @args }
function gb    { git branch @args }
function gsw   { git switch @args }
function gcp   { git cherry-pick @args }
function gcom  { git add .; git commit -m ($args -join ' ') }
function lazyg { git add .; git commit -m ($args -join ' '); git push }
function gclean         { git clean -fd @args }
function gclean-preview { git clean -fdn @args }

# ---- Docker Shortcuts ----
function dps   { docker ps @args }
function dpa   { docker ps -a @args }
function di    { docker images @args }
function dlogs { docker logs -f @args }
function dexec { docker exec -it @args }
function dstop { docker stop @args }
function drm   { docker rm @args }

# ---- System & Utilities ----
function df       { Get-Volume }
function k9       { param([Parameter(Mandatory)][string]$Name) pkill $Name }
function export   { param([string]$Name, [string]$Value) Set-Item -Path "env:$Name" -Value $Value -Force }
function touch    { param([string]$File) New-Item -ItemType File -Path $File -Force | Out-Null }
function mkcd     { param([string]$Path) New-Item -ItemType Directory -Force -Path $Path | Out-Null; Set-Location $Path }
function cpy      { Set-Clipboard ($args -join ' ') }
function pst      { Get-Clipboard }

Set-Alias cls Clear-Host -Option AllScope