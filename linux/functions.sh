# Small shell functions shared by interactive Bash and Zsh sessions.

# Navigation helpers
mkcd() {
    local directory="${1:?Usage: mkcd DIRECTORY}"
    mkdir -p -- "$directory" && cd -- "$directory"
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
        *.gz) gunzip "$archive" ;;
        *.bz2) bunzip2 "$archive" ;;
        *.xz) unxz "$archive" ;;
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

path() {
    printf '%s\n' "$PATH" | tr ':' '\n'
}