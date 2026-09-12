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
    Set-PSReadLineOption -HistoryNoDuplicates
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineOption -MaximumHistoryCount 10000
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
    Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
    Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo
    Set-PSReadLineOption -AddToHistoryHandler {
        param([string]$Line)
        $Line -notmatch '(?i)(password|secret|token|apikey|connectionstring)'
    }
}

# Small native completions keep common development commands discoverable.
Register-ArgumentCompleter -Native -CommandName git -ScriptBlock {
    param($WordToComplete)
    'status', 'add', 'commit', 'diff', 'log', 'push', 'pull', 'switch', 'checkout', 'clone' |
        Where-Object { $_ -like "$WordToComplete*" } |
        ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}

Register-ArgumentCompleter -Native -CommandName npm -ScriptBlock {
    param($WordToComplete)
    'install', 'run', 'test', 'build', 'start', 'ci' |
        Where-Object { $_ -like "$WordToComplete*" } |
        ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}