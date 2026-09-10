# ============================================================
# PowerShell Profile — main entry point
# Loads everything from ~\dotfiles\windows\ in order.
# ============================================================

$DotfilesRoot = Split-Path -Parent $PSScriptRoot   # ~/dotfiles

# ---- Environment (PATH, EDITOR, etc.) ----
. "$PSScriptRoot\env.ps1"

# ---- Aliases + Functions ----
. "$PSScriptRoot\aliases.ps1"
. "$PSScriptRoot\functions.ps1"

# ---- Modules (choco, posh-git, etc.) ----
. "$PSScriptRoot\modules.ps1"

# ---- Prompt / Starship ----
. "$PSScriptRoot\prompt.ps1"