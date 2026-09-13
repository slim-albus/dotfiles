# Small shell functions shared by interactive Bash and Zsh sessions.

# Navigation helpers
mkcd() {
    local directory="${1:?Usage: mkcd DIRECTORY}"
    mkdir -p -- "$directory" && cd -- "$directory"
}

mktempdir() {
    local directory
    directory="$(mktemp -d "${TMPDIR:-/tmp}/shell.XXXXXX")" || return 1
    cd -- "$directory"
    printf '%s\n' "$directory"
}

project_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

croot() {
    cd -- "$(project_root)"
}

up() {
    local levels="${1:-1}"
    local path='.'
    for ((index = 0; index < levels; index++)); do
        path+='/..'
    done
    cd -- "$path"
}

# Network and local development helpers
port() {
    local port_number="${1:?Usage: port PORT}"
    if command -v ss >/dev/null 2>&1; then
        ss -ltnp "sport = :$port_number"
    elif command -v lsof >/dev/null 2>&1; then
        lsof -nP -iTCP:"$port_number" -sTCP:LISTEN
    else
        printf 'Install ss or lsof to inspect listening ports.\n' >&2
        return 1
    fi
}

killport() {
    local port_number="${1:?Usage: killport PORT}"
    local pids
    if command -v lsof >/dev/null 2>&1; then
        pids="$(lsof -tiTCP:"$port_number" -sTCP:LISTEN)"
    elif command -v fuser >/dev/null 2>&1; then
        pids="$(fuser "$port_number"/tcp 2>/dev/null)"
    else
        printf 'Install lsof or fuser to stop a process by port.\n' >&2
        return 1
    fi
    [[ -n "$pids" ]] || { printf 'Nothing is listening on port %s.\n' "$port_number"; return 0; }
    kill $pids
    printf 'Stopped process(es) on port %s.\n' "$port_number"
}

psg() {
    local pattern="${1:?Usage: psg PATTERN}"
    ps aux | grep -i -- "$pattern" | grep -v '[g]rep'
}

sysinfo() {
    printf 'OS: '; uname -srm
    printf 'Host: '; hostname
    printf 'Uptime: '; uptime -p 2>/dev/null || uptime
    printf 'Memory: '; free -h 2>/dev/null | awk 'NR == 2 { print $3 " / " $2 }'
    printf 'Disk: '; df -h . | awk 'NR == 2 { print $3 " / " $2 " (" $5 ")" }'
}

weather() {
    local location="${1:-}"
    command -v curl >/dev/null 2>&1 || { printf 'curl is required for weather.\n' >&2; return 1; }
    curl -fsSL "https://wttr.in/${location}?format=3"
}

backup() {
    local source="${1:?Usage: backup FILE}"
    [[ -e "$source" || -L "$source" ]] || { printf 'Not found: %s\n' "$source" >&2; return 1; }
    local destination="${source}.$(date +%Y%m%d-%H%M%S).bak"
    cp -a -- "$source" "$destination" && printf '%s\n' "$destination"
}

serve() {
    local directory="${1:-.}"
    local port_number="${2:-8000}"
    if command -v python3 >/dev/null 2>&1; then
        (cd -- "$directory" && python3 -m http.server "$port_number")
    elif command -v python >/dev/null 2>&1; then
        (cd -- "$directory" && python -m http.server "$port_number")
    else
        printf 'Python is required for serve.\n' >&2
        return 1
    fi
}

# Archive and data helpers
extract() {
    local archive="${1:?Usage: extract ARCHIVE}"
    [[ -f "$archive" ]] || { printf 'Not found: %s\n' "$archive" >&2; return 1; }

    case "$archive" in
        *.tar.gz|*.tgz) tar -xzf "$archive" ;;
        *.tar.bz2|*.tbz2) tar -xjf "$archive" ;;
        *.tar.xz|*.txz) tar -xJf "$archive" ;;
        *.tar) tar -xf "$archive" ;;
        *.zip) unzip "$archive" ;;
        *.7z) 7z x "$archive" ;;
        *.rar) unrar x "$archive" ;;
        *.gz) gunzip "$archive" ;;
        *.bz2) bunzip2 "$archive" ;;
        *.xz) unxz "$archive" ;;
        *.zst) unzstd "$archive" ;;
        *) printf 'Unsupported archive type: %s\n' "$archive" >&2; return 1 ;;
    esac
}

# Python and shell lifecycle helpers
json() {
    local file="${1:?Usage: json FILE}"
    if command -v jq >/dev/null 2>&1; then
        jq . "$file"
    else
        printf 'jq is required for json.\n' >&2
        return 1
    fi
}

venv() {
    local directory="${1:-.venv}"
    command -v python3 >/dev/null 2>&1 || { printf 'python3 is required for venv.\n' >&2; return 1; }
    python3 -m venv "$directory" && source "$directory/bin/activate"
}

reload() {
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        source "$HOME/.zshrc"
    else
        source "$HOME/.bashrc"
    fi
}

bigfiles() {
    local directory="${1:-.}"
    local count="${2:-20}"
    du -ah -- "$directory" 2>/dev/null | sort -hr | head -n "$count"
}

treeview() {
    local directory="${1:-.}"
    local output_file="${2:-}"
    command -v tree >/dev/null 2>&1 || {
        printf 'tree is required for treeview.\n' >&2
        return 1
    }
    [[ -d "$directory" ]] || {
        printf 'Not a directory: %s\n' "$directory" >&2
        return 1
    }

    if [[ -n "$output_file" ]]; then
        tree -a --dirsfirst -- "$directory" >"$output_file"
    else
        tree -a --dirsfirst -- "$directory"
    fi
}

doctor() {
    local failed=0
    local expected_source="$DOTFILES_ROOT/linux/bashrc"
    local expected_zsh_source="$DOTFILES_ROOT/linux/zshrc"
    printf 'Dotfiles doctor\n'
    for command_name in git zsh; do
        if command -v "$command_name" >/dev/null 2>&1; then
            printf 'OK   command: %s\n' "$command_name"
        else
            printf 'MISS command: %s\n' "$command_name"
            failed=1
        fi
    done
    [[ -L "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml" && "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml" -ef "$DOTFILES_ROOT/shared/starship.toml" ]] &&
        printf 'OK   starship link\n' || { printf 'MISS starship link\n'; failed=1; }
    grep -Fqx "source \"$expected_source\"" "$HOME/.bashrc" 2>/dev/null &&
        printf 'OK   bash startup\n' || { printf 'MISS bash startup\n'; failed=1; }
    grep -Fqx "source \"$expected_zsh_source\"" "$HOME/.zshrc" 2>/dev/null &&
        printf 'OK   zsh startup\n' || { printf 'MISS zsh startup\n'; failed=1; }
    return "$failed"
}

path() {
    printf '%s\n' "$PATH" | tr ':' '\n'
}