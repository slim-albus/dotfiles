# ============================================================
# Modules & Interactive Autocomplete Configuration
# ============================================================

# ---- Optional Module Imports (Direct Fast-Paths) ----
# Terminal-Icons
$terminalIconsPath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules\Terminal-Icons'
if (Test-Path -LiteralPath $terminalIconsPath) {
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
}

# posh-git
$poshGitPath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules\posh-git'
if (Test-Path -LiteralPath $poshGitPath) {
    Import-Module posh-git -ErrorAction SilentlyContinue
}

# Chocolatey tab-completion
if ($env:ChocolateyInstall) {
    $chocoProfile = Join-Path $env:ChocolateyInstall 'helpers\chocolateyProfile.psm1'
    if (Test-Path -LiteralPath $chocoProfile) {
        Import-Module $chocoProfile -ErrorAction SilentlyContinue
    }
}

# ---- PSReadLine Modern Autocomplete & Keybindings ----
# PSReadLine is built into PowerShell 7+
if ($global:IsInteractiveShell) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue

    try {
        $psReadLineOptions = @{
            EditMode                      = 'Windows'
            HistoryNoDuplicates          = $true
            HistorySearchCursorMovesToEnd = $true
            MaximumHistoryCount          = 15000
            BellStyle                    = 'None'
            PredictionSource             = 'HistoryAndPlugin'
            PredictionViewStyle          = 'InlineView'
            Colors                       = @{
                Command          = '#87CEEB'   # Sky Blue
                Parameter        = '#98FB98'   # Pale Green
                Operator         = '#FFB6C1'   # Light Pink
                Variable         = '#DDA0DD'   # Plum
                String           = '#FFDAB9'   # Peach
                Number           = '#B0E0E6'   # Powder Blue
                Type             = '#F0E68C'   # Khaki
                Comment          = '#6C7086'   # Slate Gray
                Keyword          = '#CBA6F7'   # Lavender
                Error            = '#F38BA8'   # Coral Red
                InlinePrediction = '#585B70'   # Muted Gray for ghost text
                ListPrediction   = '#89B4FA'   # Blue highlight
            }
        }

        # Fallback for Windows PowerShell 5.1 where PredictionSource is unsupported
        if ($PSVersionTable.PSEdition -ne 'Core') {
            $psReadLineOptions.Remove('PredictionSource')
            $psReadLineOptions.Remove('PredictionViewStyle')
        }

        Set-PSReadLineOption @psReadLineOptions

        # Keybindings
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Key F2 -Function SwitchPredictionView
        Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function AcceptNextSuggestionWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
        Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
        Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
        Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
        Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo

        # History Secret Scrubber
        Set-PSReadLineOption -AddToHistoryHandler {
            param([string]$line)
            $line -notmatch '(?i)(password|secret|token|apikey|connectionstring|bearer\s+[a-z0-9_\-\.]+)'
        }
    } catch {}
}

# ---- Rich Native Argument Completers ----
if ($global:IsInteractiveShell) {
    # Bun argument completion (with package.json scripts auto-discovery)
    Register-ArgumentCompleter -Native -CommandName bun -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        $elements = $commandAst.CommandElements
        $subcommands = @(
            'add', 'install', 'remove', 'update', 'run', 'test', 'build',
            'dev', 'init', 'create', 'pm', 'upgrade', 'outdated', 'patch',
            'link', 'unlink'
        )

        if ($elements.Count -le 2) {
            $subcommands | Where-Object { $_ -like "$wordToComplete*" } |
                ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "bun $_") }
        } elseif ($elements[1].Value -eq 'run' -and $elements.Count -le 3) {
            if (Test-Path -LiteralPath 'package.json') {
                try {
                    $pkg = Get-Content -LiteralPath 'package.json' -Raw | ConvertFrom-Json
                    if ($pkg.scripts) {
                        $pkg.scripts.PSObject.Properties.Name |
                            Where-Object { $_ -like "$wordToComplete*" } |
                            ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "npm script: $_") }
                    }
                } catch {}
            }
        }
    }

    # Git argument completion (subcommands & branch names)
    Register-ArgumentCompleter -Native -CommandName git -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        $elements = $commandAst.CommandElements
        $subcommands = @(
            'status', 'add', 'commit', 'push', 'pull', 'fetch', 'checkout', 'switch',
            'branch', 'diff', 'log', 'rebase', 'merge', 'stash', 'cherry-pick',
            'reset', 'restore', 'clean', 'tag', 'remote', 'clone'
        )

        if ($elements.Count -le 2) {
            $subcommands | Where-Object { $_ -like "$wordToComplete*" } |
                ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "git $_") }
        } elseif ($elements[1].Value -in @('checkout', 'switch', 'branch', 'merge', 'rebase')) {
            # Local branches
            try {
                $branches = git branch --format="%(refname:short)" 2>$null
                $branches | Where-Object { $_ -like "$wordToComplete*" } |
                    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "branch: $_") }
            } catch {}
        }
    }

    # Winget argument completion
    Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        $elements = $commandAst.CommandElements
        $subcommands = @('install', 'uninstall', 'upgrade', 'show', 'search', 'list', 'source', 'settings', 'export', 'import')
        if ($elements.Count -le 2) {
            $subcommands | Where-Object { $_ -like "$wordToComplete*" } |
                ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "winget $_") }
        }
    }

    # Docker argument completion
    Register-ArgumentCompleter -Native -CommandName docker -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        $elements = $commandAst.CommandElements
        $subcommands = @('ps', 'images', 'run', 'exec', 'stop', 'rm', 'rmi', 'logs', 'compose', 'build', 'pull', 'push', 'restart', 'inspect', 'volume', 'network', 'system')
        if ($elements.Count -le 2) {
            $subcommands | Where-Object { $_ -like "$wordToComplete*" } |
                ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "docker $_") }
        }
    }
}