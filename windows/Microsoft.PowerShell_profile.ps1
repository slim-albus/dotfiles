# ============================================================
# PowerShell Profile — main entry point
# Loads everything from ~\dotfiles\windows\ in order.
# ============================================================

$scriptPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
if (-not $scriptPath -and (Test-Path "$HOME\dotfiles\windows")) {
    $scriptPath = "$HOME\dotfiles\windows"
}
$global:DotfilesRoot = Split-Path -Parent $scriptPath

# Determine interactive shell capability
$global:IsInteractiveShell = try {
    ($Host.Name -eq 'ConsoleHost' -or $Host.Name -eq 'Visual Studio Code Host') -and
    -not [Console]::IsInputRedirected -and
    -not [Console]::IsOutputRedirected
} catch {
    $false
}

# Set console title if interactive
if ($global:IsInteractiveShell) {
    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        $adminTag = if ($isAdmin) { ' [ADMIN]' } else { '' }
        $Host.UI.RawUI.WindowTitle = "PowerShell $($PSVersionTable.PSVersion)$adminTag"
    } catch {}
}

# ---- Environment (PATH, EDITOR, etc.) ----
. "$scriptPath\env.ps1"

# ---- Aliases + Functions ----
. "$scriptPath\aliases.ps1"
. "$scriptPath\functions.ps1"

# ---- Modules & Completions (PSReadLine, bun, git) ----
. "$scriptPath\modules.ps1"

# ---- Prompt / Starship ----
. "$scriptPath\prompt.ps1"