#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0

usage() {
    cat <<'EOF'
Usage: ./install.sh [--dry-run]

Verify Git, then install the shared and shell configuration for the current
user.
Existing files are backed up with a .dotfiles-backup suffix before they are
replaced. The installer does not install packages or require root access.
EOF
}

log() {
    printf '  %s\n' "$*"
}

run() {
    if (( DRY_RUN )); then
        log "dry-run: $*"
    else
        "$@"
    fi
}

verify_required_tools() {
    local missing=()
    command -v git >/dev/null 2>&1 || missing+=(git)

    if ((${#missing[@]})); then
        printf 'Required tools are missing:\n' >&2
        printf '  %s\n' "${missing[@]}" >&2
        printf 'Run ./install-packages.sh first, then run ./install.sh again.\n' >&2
        return 1
    fi
    log 'verified required installer tools'
}

clone_if_missing() {
    local repository="$1"
    local target="$2"

    if [[ -d "$target" ]]; then
        log "already installed: $target"
        return 0
    fi
    run git clone --depth=1 "$repository" "$target"
    log "installed $target"
}

setup_oh_my_zsh() {
    local oh_my_zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
    local custom_dir="$oh_my_zsh_dir/custom"

    if ! command -v git >/dev/null 2>&1; then
        log "skipping Oh My Zsh: git is not installed"
        return 0
    fi

    clone_if_missing \
        "https://github.com/ohmyzsh/ohmyzsh.git" \
        "$oh_my_zsh_dir"
    clone_if_missing \
        "https://github.com/zsh-users/zsh-autosuggestions.git" \
        "$custom_dir/plugins/zsh-autosuggestions"
    clone_if_missing \
        "https://github.com/marlonrichert/zsh-autocomplete.git" \
        "$custom_dir/plugins/zsh-autocomplete"
}

backup_if_needed() {
    local target="$1"
    local backup="${target}.dotfiles-backup"

    [[ -e "$target" || -L "$target" ]] || return 0
    [[ "$target" -ef "$2" ]] && return 0

    if [[ -e "$backup" || -L "$backup" ]]; then
        backup="${backup}.$(date +%Y%m%d%H%M%S)"
    fi
    run mv "$target" "$backup"
    log "backed up $target to $backup"
}

link_file() {
    local source="$1"
    local target="$2"

    run mkdir -p "$(dirname -- "$target")"
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ "$target" -ef "$source" ]]; then
            log "already linked: $target"
            return 0
        fi
        backup_if_needed "$target" "$source"
    fi
    run ln -s "$source" "$target"
    log "linked $target"
}

ensure_source_line() {
    local file="$1"
    local source="$2"
    local marker="# dotfiles: load shell configuration"

    if (( DRY_RUN )); then
        if [[ -f "$file" ]] && grep -Fqx "$source" "$file"; then
            return 0
        fi
        log "dry-run: add shell source to $file"
        return 0
    fi

    touch "$file"
    grep -Fqx "$source" "$file" 2>/dev/null && return 0
    printf '\n%s\n%s\n' "$marker" "$source" >> "$file"
    log "configured $file"
}

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

# The Unix installer is intentionally separate from the Windows installer.
if [[ "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* ]]; then
    printf 'Use windows/install.ps1 from PowerShell on Windows.\n' >&2
    exit 1
fi

verify_required_tools

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
shell_entry="source \"$DOTFILES_ROOT/linux/bashrc\""
zsh_entry="source \"$DOTFILES_ROOT/linux/zshrc\""

# Link shared configuration and register shell startup files.
link_file "$DOTFILES_ROOT/shared/starship.toml" "$config_dir/starship.toml"
link_file "$DOTFILES_ROOT/shared/git/config" "$config_dir/git/config"
link_file "$DOTFILES_ROOT/shared/git/ignore" "$config_dir/git/ignore"
link_file "$DOTFILES_ROOT/shared/tmux/tmux.conf" "$config_dir/tmux/tmux.conf"
setup_oh_my_zsh
ensure_source_line "$HOME/.bashrc" "$shell_entry"
ensure_source_line "$HOME/.zshrc" "$zsh_entry"

printf 'Dotfiles installed from %s\n' "$DOTFILES_ROOT"