# ============================================================
# Aliases
# ============================================================

# ---- Navigation ----
function ..  { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function ~   { Set-Location $HOME }

# ---- Listing ----
# Use eza if installed, else fall back to Get-ChildItem
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ll { eza -la --icons --git }
    function l  { eza -l  --icons --git }
    function la { eza -a  --icons }
    function ls { eza     --icons }
} else {
    function ll { Get-ChildItem -Force }
    function l  { Get-ChildItem }
    function la { Get-ChildItem -Force }
    Set-Alias ls Get-ChildItem
}

# ---- Git (mirrors common bash aliases) ----
function gs  { git status }
function ga  { git add }
function gc  { git commit }
function gp  { git push }
function gl  { git log --oneline --graph --decorate -20 }
function gd  { git diff }
function gco { git checkout }
function gb  { git branch }
function gsw { git switch $args }
function gcp { git cherry-pick $args }
function gclean { git clean -fd $args }

# Docker shortcuts
function dps { docker ps }
function dpa { docker ps -a }
function di { docker images }
function dlogs { docker logs -f $args }
function dexec { docker exec -it $args }
function dstop { docker stop $args }
function drm { docker rm $args }

# ---- System ----
function which { Get-Command $args[0] | Select-Object -ExpandProperty Source }
function touch { New-Item -ItemType File -Path $args[0] -Force | Out-Null }
function mkcd  {
    param([string]$Path)
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Set-Location $Path
}

# ---- Clear ----
Set-Alias cls Clear-Host