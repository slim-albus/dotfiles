#!/usr/bin/env bash
# ============================================================
# dots — Interactive Dotfiles Manual & Cheat Sheet (Linux/Unix)
# ============================================================

dots() {
    local topic="${1:-}"
    local query="${2:-}"

    # ANSI Colors
    local c_cyan='\033[0;36m'
    local c_yellow='\033[1;33m'
    local c_green='\033[0;32m'
    local c_white='\033[0;37m'
    local c_gray='\033[0;90m'
    local c_reset='\033[0m'

    # Handle Subcommands
    if [[ "$topic" == "doctor" ]]; then
        doctor
        return 0
    fi

    if [[ "$topic" == "update" ]]; then
        printf "${c_cyan}Updating dotfiles...${c_reset}\n"
        local root="${DOTFILES_ROOT:-$HOME/dotfiles}"
        if [[ -d "$root/.git" ]]; then
            (cd -- "$root" && git pull)
            rm -rf -- "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"/* 2>/dev/null || true
            rm -rf -- "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"/* 2>/dev/null || true
            printf "${c_green}Reloading profile...${c_reset}\n"
            reload
        else
            printf "Not a git repository: %s\n" "$root" >&2
            return 1
        fi
        return 0
    fi

    # Database of dotfiles commands: Category|Command|Description
    local items=(
        "nav|.. / ... / ....|Go up 1, 2, or 3 directories"
        "nav|~|Go to home directory (\$HOME)"
        "nav|croot|Change directory to current Git repository root"
        "nav|project_root|Print the current Git root path"
        "nav|mkcd <dir>|Create directory and enter it"
        "nav|up [n]|Move up N directory levels (defaults to 1)"
        "nav|docs / dtop|Go to Documents or Desktop directory"
        "nav|mktempdir|Create and enter a fresh temporary directory"
        "nav|z <query>|Smart directory jumping with zoxide"
        "nav|zi <query>|Interactive fuzzy directory jumping"
        "files|ll / l / la / ls|Enhanced listing (eza with icons or formatted)"
        "files|bigfiles [dir] [n]|List largest files in directory (default: top 20)"
        "files|treeview [dir] [f]|Print hierarchical directory tree (requires tree)"
        "files|extract <archive>|Extract tar, zip, gz, bz2, 7z, xz, zst archives"
        "files|trash <path>|Safely move file/dir to Trash (via trash-cli/gio)"
        "files|json <file>|Pretty-print JSON with jq"
        "files|head / tail <f>|Show first or last lines of file"
        "files|backup <file>|Create a timestamped backup copy (.bak)"
        "git|gs|git status"
        "git|ga [files]|git add (accepts arguments, or .)"
        "git|gc|git commit (opens micro for message)"
        "git|gcom <msg>|git add . && git commit -m <msg>"
        "git|lazyg <msg>|git add . && git commit -m <msg> && git push"
        "git|gp|git push (auto-sets upstream branch)"
        "git|gpull|git pull (prunes deleted remote branches)"
        "git|gl|Pretty 20-line graph commit log"
        "git|gd|git diff (histogram algorithm)"
        "git|gco <branch>|git checkout"
        "git|gsw <branch>|git switch"
        "git|gb|git branch"
        "git|gcp <hash>|git cherry-pick"
        "git|gclean-preview|Preview untracked files to be deleted (-fdn)"
        "git|gclean|Force clean untracked files (-fd)"
        "docker|dps / dpa|List running / all Docker containers"
        "docker|di|List local Docker images"
        "docker|dlogs <c>|Follow container logs (-f)"
        "docker|dexec <c> [cmd]|Interactive terminal into container (default: sh)"
        "docker|dstop / drm <c>|Stop / remove Docker container"
        "dev|bun <cmd>|Fast TS/JS runtime with argument completions"
        "dev|serve [dir] [p]|Start local Python HTTP server (default: port 8000)"
        "dev|venv [dir]|Create and activate Python virtual environment (.venv)"
        "dev|port <num>|Show which process is listening on local TCP port"
        "dev|killport <num>|Terminate process(es) holding a local TCP port"
        "dev|reload|Reload current shell configuration (bashrc/zshrc)"
        "sys|admin / su|Run command with sudo (or sudo -i if no args)"
        "sys|sysinfo|Show system info banner (fastfetch or uname/free/df)"
        "sys|flushdns|Flush systemd-resolved DNS resolver cache"
        "sys|psg <pattern>|Search running processes matching pattern"
        "sys|k9 <name>|Kill processes by name (pkill -9 -f)"
        "sys|weather [loc]|Query live weather from wttr.in"
        "sys|cpy / pst|Copy or paste clipboard text (wl-copy, xclip, clip.exe)"
        "sys|df|Show disk volume usage in human-readable format"
        "keys|Tab / Shift+Tab|Interactive completion menu (cycles forward / backward)"
        "keys|Up / Down Arrow|History search matching current typed prefix"
        "keys|Ctrl+f / Right |Accept autosuggestion word / line (Zsh)"
        "keys|Ctrl+r         |History reverse search (or fzf history if installed)"
        "keys|Ctrl+w         |Delete previous word on command line"
        "keys|Ctrl+u         |Clear entire line before cursor"
        "keys|Ctrl+a / Ctrl+e|Move to beginning / end of command line"
    )

    local cat_names=("nav" "files" "git" "docker" "dev" "sys" "keys")
    local cat_titles=(
        "Navigation & Locations"
        "File & Archive Helpers"
        "Git Shortcuts"
        "Docker Helpers"
        "Development & Runtimes"
        "System & Utilities"
        "Autocomplete & Keybindings"
    )

    # Search Mode
    local search_term=""
    if [[ "$topic" == "find" || "$topic" == "search" ]]; then
        search_term="$query"
    elif [[ -n "$topic" ]]; then
        local is_cat=0
        for c in "${cat_names[@]}"; do
            if [[ "$topic" == "$c" ]]; then
                is_cat=1
                break
            fi
        done
        [[ $is_cat -eq 0 ]] && search_term="$topic"
    fi

    if [[ -n "$search_term" ]]; then
        printf "\n  ${c_cyan}Dotfiles Search Results for: '%s'${c_reset}\n" "$search_term"
        printf "  ${c_gray}========================================================${c_reset}\n"
        local match_count=0
        local last_cat=""
        for item in "${items[@]}"; do
            local cat="${item%%|*}"
            local rest="${item#*|}"
            local cmd="${rest%%|*}"
            local desc="${rest#*|}"

            if [[ "$cmd" == *"$search_term"* || "$desc" == *"$search_term"* ]]; then
                if [[ "$cat" != "$last_cat" ]]; then
                    local title="$cat"
                    for ((i=0; i<${#cat_names[@]}; i++)); do
                        [[ "${cat_names[i]}" == "$cat" ]] && title="${cat_titles[i]}"
                    done
                    printf "\n  ${c_yellow}[%s]${c_reset}\n" "$title"
                    last_cat="$cat"
                fi
                printf "  ${c_green}%-22s${c_reset} : %s\n" "$cmd" "$desc"
                match_count=$((match_count + 1))
            fi
        done

        if (( match_count == 0 )); then
            printf "\n  ${c_yellow}No commands or aliases found matching '%s'.${c_reset}\n" "$search_term"
            printf "  ${c_gray}Run 'dots' to view the complete cheat sheet.${c_reset}\n"
        fi
        printf "\n"
        return 0
    fi

    # Filtered by Category Mode
    local filter_cat=""
    if [[ -n "$topic" ]]; then
        for c in "${cat_names[@]}"; do
            if [[ "$topic" == "$c" ]]; then
                filter_cat="$c"
                break
            fi
        done
    fi

    # Print Header
    printf "\n  ${c_cyan}========================================================${c_reset}\n"
    printf "  ${c_cyan}             Dotfiles Command Reference (Linux)         ${c_reset}\n"
    printf "  ${c_cyan}========================================================${c_reset}\n"
    printf "  ${c_gray}Tip: Run 'dots <category>' (nav, files, git, docker, dev, sys, keys)${c_reset}\n"
    printf "  ${c_gray}     Run 'dots <search>' to search | 'dots doctor' for health${c_reset}\n"

    for ((i=0; i<${#cat_names[@]}; i++)); do
        local cat="${cat_names[i]}"
        local title="${cat_titles[i]}"

        if [[ -n "$filter_cat" && "$cat" != "$filter_cat" ]]; then
            continue
        fi

        printf "\n  ${c_yellow}--- %s ---${c_reset}\n" "$title"
        for item in "${items[@]}"; do
            local item_cat="${item%%|*}"
            if [[ "$item_cat" == "$cat" ]]; then
                local rest="${item#*|}"
                local cmd="${rest%%|*}"
                local desc="${rest#*|}"
                printf "  ${c_green}%-22s${c_reset} : %s\n" "$cmd" "$desc"
            fi
        done
    done

    printf "\n  ${c_cyan}========================================================${c_reset}\n\n"
}

alias cheat='dots'
alias dotfiles='dots'
alias help-dots='dots'
