# ============================================================
# Module imports
# ============================================================

# ---- Chocolatey tab-completion ----
if ($env:ChocolateyInstall) {
    $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
    if (Test-Path $ChocolateyProfile) {
        Import-Module $ChocolateyProfile
    }
}

# ---- posh-git (if installed) ----
if (Get-Module -ListAvailable -Name posh-git) {
    Import-Module posh-git
}

# ---- PSReadLine tweaks (smarter history search) ----
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}