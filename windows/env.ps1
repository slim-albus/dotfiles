# ============================================================
# Environment variables
# ============================================================

# Default editor
$env:EDITOR = "micro"       # or nvim, code, notepad++, etc.

# Better ls/pager defaults
$env:PAGER = "less"

# Tell Starship where its config lives (so it doesn't need a symlink)
$env:STARSHIP_CONFIG = Join-Path $DotfilesRoot "shared\starship.toml"

# ---- PATH additions ----
# Helper: prepend a path only if it exists and isn't already present
function Add-ToPath {
    param([string]$Path)
    if ((Test-Path $Path) -and ($env:Path -notlike "*$Path*")) {
        $env:Path = "$Path;$env:Path"
    }
}

Add-ToPath "$HOME\.local\bin"
Add-ToPath "$HOME\.cargo\bin"
Add-ToPath "$HOME\go\bin"
Add-ToPath "$HOME\scoop\shims"
Add-ToPath "$env:USERPROFILE\bin"

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { zoxide init powershell | Out-String })
}

if (Get-Command direnv -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { direnv hook pwsh | Out-String })
}

Remove-Item Function:\Add-ToPath  # keep global namespace clean