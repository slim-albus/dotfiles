# Small shell functions shared by interactive Bash and Zsh sessions.

# Load the interactive manual 'dots' if present
if [[ -r "${DOTFILES_ROOT:-$HOME/dotfiles}/linux/dots.sh" ]]; then
    source "${DOTFILES_ROOT:-$HOME/dotfiles}/linux/dots.sh"
fi

# ---- Navigation Helpers ----
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

# ---- Network and Local Development Helpers ----
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

k9() {
    local name="${1:?Usage: k9 PROCESS_NAME}"
    pkill -9 -f "$name"
}

# ---- System and Utilities ----
admin() {
    if (( $# == 0 )); then
        sudo -i
    else
        sudo "$@"
    fi
}
alias su='admin'

trash() {
    local target="${1:?Usage: trash PATH}"
    [[ -e "$target" || -L "$target" ]] || { printf 'Not found: %s\n' "$target" >&2; return 1; }
    if command -v trash-put >/dev/null 2>&1; then
        trash-put "$target"
    elif command -v gio >/dev/null 2>&1; then
        gio trash "$target"
    else
        local trash_dir="${XDG_DATA_HOME:-$HOME/.local/share}/Trash/files"
        mkdir -p -- "$trash_dir"
        mv -- "$target" "$trash_dir/"
        printf 'Moved to Trash: %s\n' "$trash_dir/$(basename -- "$target")"
    fi
}

sysinfo() {
    local ff_config="${DOTFILES_ROOT:-$HOME/dotfiles}/shared/fastfetch/config.jsonc"
    if command -v fastfetch >/dev/null 2>&1; then
        if [[ -r "$ff_config" ]]; then
            fastfetch -c "$ff_config"
        else
            fastfetch
        fi
    else
        printf 'OS: '; uname -srm
        printf 'Host: '; hostname
        printf 'Uptime: '; uptime -p 2>/dev/null || uptime
        printf 'Memory: '; free -h 2>/dev/null | awk 'NR == 2 { print $3 " / " $2 }'
        printf 'Disk: '; df -h . | awk 'NR == 2 { print $3 " / " $2 " (" $5 ")" }'
    fi
}

flushdns() {
    if command -v resolvectl >/dev/null 2>&1; then
        sudo resolvectl flush-caches && printf 'DNS cache flushed (resolvectl).\n'
    elif command -v systemd-resolve >/dev/null 2>&1; then
        sudo systemd-resolve --flush-caches && printf 'DNS cache flushed (systemd-resolve).\n'
    elif [[ -f /etc/init.d/nscd ]]; then
        sudo /etc/init.d/nscd restart && printf 'DNS cache flushed (nscd).\n'
    else
        printf 'No supported DNS resolver cache flush mechanism found.\n' >&2
        return 1
    fi
}

cpy() {
    if command -v wl-copy >/dev/null 2>&1; then
        wl-copy "$@"
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard "$@"
    elif command -v clip.exe >/dev/null 2>&1; then
        clip.exe "$@"
    else
        printf 'Install wl-copy or xclip for clipboard support.\n' >&2
        return 1
    fi
}

pst() {
    if command -v wl-paste >/dev/null 2>&1; then
        wl-paste "$@"
    elif command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard -o "$@"
    elif command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -NoProfile -Command Get-Clipboard
    else
        printf 'Install wl-paste or xclip for clipboard support.\n' >&2
        return 1
    fi
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

# ---- Git Workflow Helpers ----
gcom() {
    git add . && git commit -m "$*"
}

lazyg() {
    git add . && git commit -m "$*" && git push
}

# ---- Development Helpers ----
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

unalias reload 2>/dev/null || true
reload() {
    rm -rf -- "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"/* 2>/dev/null || true
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        source "$HOME/.zshrc"
    else
        source "$HOME/.bashrc"
    fi
    printf 'Profile reloaded.\n'
}

history-import-bash() {
    local bash_history="${1:-$HOME/.bash_history}"
    [[ -n "${ZSH_VERSION:-}" ]] || { printf 'history-import-bash is available in Zsh only.\n' >&2; return 1; }
    [[ -r "$bash_history" ]] || { printf 'Not found: %s\n' "$bash_history" >&2; return 1; }
    fc -R "$bash_history"
    fc -W "$HISTFILE"
    printf 'Imported Bash history from %s.\n' "$bash_history"
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

doctor() {
    local failed=0
    local root="${DOTFILES_ROOT:-$HOME/dotfiles}"
    local expected_source="$root/linux/bashrc"
    local expected_zsh_source="$root/linux/zshrc"
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"

    printf '\n  Dotfiles Health Check (Linux/Unix)\n'
    printf '  ==================================================\n'

    local tools=(git bash zsh bun starship zoxide micro fastfetch)
    local bin_path=""
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            bin_path="$(command -v "$tool")"
            printf '  [ OK ] %-12s : %s\n' "$tool" "$bin_path"
        else
            printf '  [MISS] %-12s : Not found in PATH\n' "$tool"
        fi
    done

    printf '\n  Configuration Links:\n'
    local links=(
        "starship.toml:$config_dir/starship.toml:$root/shared/starship.toml"
        "git/config:$config_dir/git/config:$root/shared/git/config"
        "git/ignore:$config_dir/git/ignore:$root/shared/git/ignore"
        "tmux.conf:$config_dir/tmux/tmux.conf:$root/shared/tmux/tmux.conf"
        "fastfetch:$config_dir/fastfetch/config.jsonc:$root/shared/fastfetch/config.jsonc"
        "micro:$config_dir/micro/settings.json:$root/shared/micro/settings.json"
    )

    for entry in "${links[@]}"; do
        local name="${entry%%:*}"
        local rest="${entry#*:}"
        local target="${rest%%:*}"
        local source="${rest#*:}"

        if [[ -L "$target" && "$target" -ef "$source" ]]; then
            printf '  [ OK ] %-16s : Linked -> %s\n' "$name" "$target"
        elif [[ -e "$target" ]]; then
            printf '  [WARN] %-16s : File exists but not linked -> %s\n' "$name" "$target"
        else
            printf '  [MISS] %-16s : Missing link -> %s\n' "$name" "$target"
            failed=1
        fi
    done

    printf '\n  Shell Startup:\n'
    if grep -Fqx "source \"$expected_source\"" "$HOME/.bashrc" 2>/dev/null; then
        printf '  [ OK ] Bash startup      : Configured in ~/.bashrc\n'
    else
        printf '  [MISS] Bash startup      : Not configured in ~/.bashrc\n'
    fi

    if command -v zsh >/dev/null 2>&1; then
        if grep -Fqx "source \"$expected_zsh_source\"" "$HOME/.zshrc" 2>/dev/null; then
            printf '  [ OK ] Zsh startup       : Configured in ~/.zshrc\n'
        else
            printf '  [MISS] Zsh startup       : Not configured in ~/.zshrc\n'
        fi
    fi
    printf '\n'
    return "$failed"
}