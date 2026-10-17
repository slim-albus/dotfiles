# ============================================================
# dots — Interactive Dotfiles Manual & Cheat Sheet
# ============================================================

function dots {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Topic,

        [Parameter(Position = 1)]
        [string]$Query,

        [switch]$List
    )

    $categories = [ordered]@{
        "nav" = @{
            Title = "Navigation & Locations"
            Items = @(
                @{ Cmd = ".. / ... / ...."; Desc = "Go up 1, 2, or 3 directories" }
                @{ Cmd = "~";               Desc = "Go to user home directory ($HOME)" }
                @{ Cmd = "croot";           Desc = "Change directory to current Git repository root" }
                @{ Cmd = "project-root";    Desc = "Print the current Git root path" }
                @{ Cmd = "mkcd <path>";     Desc = "Create directory (including parents) and enter it" }
                @{ Cmd = "up [n]";          Desc = "Move up N directory levels (defaults to 1)" }
                @{ Cmd = "docs";            Desc = "Go to Documents directory" }
                @{ Cmd = "dtop";            Desc = "Go to Desktop directory" }
                @{ Cmd = "mktempdir";       Desc = "Create and enter a fresh random temporary directory" }
                @{ Cmd = "z <query>";       Desc = "Smart directory jumping with zoxide" }
                @{ Cmd = "zi <query>";      Desc = "Interactive fuzzy directory jumping" }
            )
        }
        "files" = @{
            Title = "File & Archive Helpers"
            Items = @(
                @{ Cmd = "ll / l / la / ls"; Desc = "Enhanced directory listing (eza with icons or formatted)" }
                @{ Cmd = "ff <name> [dir]";  Desc = "Find files recursively matching name filter" }
                @{ Cmd = "Show-Tree [path]"; Desc = "Print hierarchical tree structure of directory" }
                @{ Cmd = "Get-BigFiles [n]"; Desc = "List largest files in directory (defaults to top 20)" }
                @{ Cmd = "extract <archive>"; Desc = "Extract zip archive into current folder" }
                @{ Cmd = "trash <path>";     Desc = "Safely move file or directory to Windows Recycle Bin" }
                @{ Cmd = "json <file>";      Desc = "Pretty-print formatted JSON with depth 100" }
                @{ Cmd = "head <file> [n]";  Desc = "Show first N lines of file (defaults to 10)" }
                @{ Cmd = "tail <file> [n]";  Desc = "Show last N lines of file (defaults to 10, -Wait supported)" }
                @{ Cmd = "touch <file>";     Desc = "Create new file or update timestamp" }
                @{ Cmd = "sed <f> <a> <b>";  Desc = "Find and replace text in file" }
                @{ Cmd = "Backup-Item <f>";  Desc = "Create a timestamped backup copy (.bak)" }
            )
        }
        "git" = @{
            Title = "Git Shortcuts"
            Items = @(
                @{ Cmd = "gs";               Desc = "git status" }
                @{ Cmd = "ga [files]";       Desc = "git add (accepts arguments, or .)" }
                @{ Cmd = "gc";               Desc = "git commit (opens editor for message)" }
                @{ Cmd = "gcom <msg>";       Desc = "git add . && git commit -m <msg>" }
                @{ Cmd = "lazyg <msg>";      Desc = "git add . && git commit -m <msg> && git push" }
                @{ Cmd = "gp";               Desc = "git push (auto-sets upstream branch)" }
                @{ Cmd = "gpull";            Desc = "git pull (prunes deleted remote branches)" }
                @{ Cmd = "gl";               Desc = "Pretty 20-line graph commit log" }
                @{ Cmd = "gd";               Desc = "git diff (histogram algorithm)" }
                @{ Cmd = "gco <branch>";     Desc = "git checkout (with tab completion)" }
                @{ Cmd = "gsw <branch>";     Desc = "git switch (with tab completion)" }
                @{ Cmd = "gb";               Desc = "git branch" }
                @{ Cmd = "gcp <hash>";       Desc = "git cherry-pick" }
                @{ Cmd = "gclean-preview";   Desc = "Preview untracked files to be deleted (-fdn)" }
                @{ Cmd = "gclean";           Desc = "Force clean untracked files (-fd)" }
            )
        }
        "docker" = @{
            Title = "Docker Helpers"
            Items = @(
                @{ Cmd = "dps";              Desc = "List running containers" }
                @{ Cmd = "dpa";              Desc = "List all containers (including stopped)" }
                @{ Cmd = "di";               Desc = "List local docker images" }
                @{ Cmd = "dlogs <container>"; Desc = "Follow container output logs (-f)" }
                @{ Cmd = "dexec <c> [cmd]";  Desc = "Interactive terminal into container (default: sh/bash)" }
                @{ Cmd = "dstop <c>";        Desc = "Stop running container" }
                @{ Cmd = "drm <c>";          Desc = "Remove container" }
            )
        }
        "dev" = @{
            Title = "Development & Runtimes"
            Items = @(
                @{ Cmd = "bun <cmd>";        Desc = "Fast TS/JS runtime with argument & script completions" }
                @{ Cmd = "serve [dir] [port]"; Desc = "Start local Python HTTP server (default: port 8000)" }
                @{ Cmd = "venv [dir]";       Desc = "Create and activate Python virtual environment (.venv)" }
                @{ Cmd = "port <num>";       Desc = "Show which process is listening on local TCP port" }
                @{ Cmd = "killport <num>";   Desc = "Terminate process(es) holding a local TCP port" }
                @{ Cmd = "ep";               Desc = "Edit current PowerShell profile in default editor" }
                @{ Cmd = "reload";           Desc = "Reload PowerShell profile in current session" }
            )
        }
        "sys" = @{
            Title = "System & Windows Tools"
            Items = @(
                @{ Cmd = "admin / su";       Desc = "Launch elevated terminal/PowerShell in current folder" }
                @{ Cmd = "sysinfo";          Desc = "Show system info banner (fastfetch or ComputerInfo)" }
                @{ Cmd = "flushdns";         Desc = "Flush Windows DNS client resolver cache" }
                @{ Cmd = "uptime";           Desc = "Show OS uptime duration" }
                @{ Cmd = "weather [loc]";    Desc = "Query live weather from wttr.in" }
                @{ Cmd = "cpy <text>";       Desc = "Copy text or pipeline input to clipboard" }
                @{ Cmd = "pst";              Desc = "Get content currently on clipboard" }
                @{ Cmd = "which <name>";     Desc = "Locate source path of command or executable" }
                @{ Cmd = "pkill <name>";     Desc = "Kill running processes matching name" }
                @{ Cmd = "pgrep <name>";     Desc = "Search running processes by name" }
                @{ Cmd = "df";               Desc = "Display volume and drive space (Get-Volume)" }
                @{ Cmd = "winutil";          Desc = "Launch Chris Titus Tech Windows Utility" }
            )
        }
        "keys" = @{
            Title = "Autocomplete & Keybindings"
            Items = @(
                @{ Cmd = "Tab";              Desc = "Interactive menu completion (cycles through candidates)" }
                @{ Cmd = "F2";               Desc = "Toggle between InlineView (ghost text) and ListView" }
                @{ Cmd = "RightArrow";       Desc = "Accept entire inline prediction at end of line" }
                @{ Cmd = "Ctrl+f";           Desc = "Accept next word of inline prediction" }
                @{ Cmd = "Up / Down Arrow";  Desc = "Search command history matching what you already typed" }
                @{ Cmd = "Ctrl+w";           Desc = "Delete word backward" }
                @{ Cmd = "Ctrl+d";           Desc = "Delete character forward" }
                @{ Cmd = "Ctrl+z / Ctrl+y";  Desc = "Undo / Redo command line edit" }
            )
        }
    }

    # Handle Subcommands
    if ($Topic -eq "doctor") {
        Invoke-DotfilesDoctor
        return
    }

    if ($Topic -eq "update") {
        Write-Host "Updating dotfiles..." -ForegroundColor Cyan
        Push-Location $global:DotfilesRoot
        try {
            git pull
            $cacheDir = Join-Path $env:LOCALAPPDATA "dotfiles-cache"
            if (Test-Path $cacheDir) { Remove-Item -Path "$cacheDir\*" -Force -ErrorAction SilentlyContinue }
            Write-Host "Reloading profile..." -ForegroundColor Green
            . $PROFILE
        } finally {
            Pop-Location
        }
        return
    }

    # Search Mode
    $hasTopic = -not [string]::IsNullOrWhiteSpace($Topic)
    $searchTerm = if ($Topic -eq "find" -or $Topic -eq "search") {
        $Query
    } elseif ($hasTopic -and -not $categories.Contains($Topic.ToLower())) {
        $Topic
    } else {
        $null
    }

    if (-not [string]::IsNullOrWhiteSpace($searchTerm)) {
        Write-Host "`n  Dotfiles Search Results for: '$searchTerm'" -ForegroundColor Cyan
        Write-Host ("  " + ("=" * 55)) -ForegroundColor DarkGray
        $matchCount = 0
        foreach ($entry in $categories.GetEnumerator()) {
            $cat = $entry.Value
            $matchingItems = @($cat.Items | Where-Object { $_.Cmd -like "*$searchTerm*" -or $_.Desc -like "*$searchTerm*" })
            if ($matchingItems.Count -gt 0) {
                Write-Host "`n  [$($cat.Title)]" -ForegroundColor Yellow
                foreach ($item in $matchingItems) {
                    $cmdText = ("  {0,-22}" -f $item.Cmd)
                    Write-Host $cmdText -ForegroundColor Green -NoNewline
                    Write-Host " : $($item.Desc)" -ForegroundColor White
                    $matchCount++
                }
            }
        }
        if ($matchCount -eq 0) {
            Write-Host "`n  No commands or aliases found matching '$searchTerm'." -ForegroundColor Yellow
            Write-Host "  Run 'dots' to view the complete cheat sheet." -ForegroundColor DarkGray
        }
        Write-Host ""
        return
    }

    # Filtered by Category Mode
    $filterCat = if ($hasTopic -and $categories.Contains($Topic.ToLower())) { $Topic.ToLower() } else { $null }

    # Print Header
    Write-Host "`n  ========================================================" -ForegroundColor Cyan
    Write-Host "               Dotfiles Command Reference               " -ForegroundColor Cyan
    Write-Host "  ========================================================" -ForegroundColor Cyan
    Write-Host "  Tip: Run 'dots <category>' (nav, files, git, docker, dev, sys, keys)" -ForegroundColor DarkGray
    Write-Host "       Run 'dots <search>' to search | 'dots doctor' for health" -ForegroundColor DarkGray

    foreach ($entry in $categories.GetEnumerator()) {
        $catKey = $entry.Key
        $cat = $entry.Value
        if ($filterCat -and $catKey -ne $filterCat) {
            continue
        }
        Write-Host "`n  --- $($cat.Title) ---" -ForegroundColor Yellow
        foreach ($item in $cat.Items) {
            $cmdText = ("  {0,-22}" -f $item.Cmd)
            Write-Host $cmdText -ForegroundColor Green -NoNewline
            Write-Host " : $($item.Desc)" -ForegroundColor White
        }
    }
    Write-Host "`n  ========================================================`n" -ForegroundColor Cyan
}

Set-Alias cheat dots -Option AllScope
Set-Alias dotfiles dots -Option AllScope
Set-Alias help-dots dots -Option AllScope
