#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0

usage() {
    cat <<'EOF'
Usage: ./install.sh [--dry-run]

Install the shared and Linux shell configuration for the current user.
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

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
shell_entry="source \"$DOTFILES_ROOT/linux/bashrc\""

# Link shared configuration and register shell startup files.
link_file "$DOTFILES_ROOT/shared/starship.toml" "$config_dir/starship.toml"
link_file "$DOTFILES_ROOT/shared/git/config" "$config_dir/git/config"
link_file "$DOTFILES_ROOT/shared/git/ignore" "$config_dir/git/ignore"
link_file "$DOTFILES_ROOT/shared/tmux/tmux.conf" "$config_dir/tmux/tmux.conf"
ensure_source_line "$HOME/.bashrc" "$shell_entry"

if [[ -f "$HOME/.zshrc" ]]; then
    ensure_source_line "$HOME/.zshrc" "source \"$DOTFILES_ROOT/linux/zshrc\""
fi

printf 'Dotfiles installed from %s\n' "$DOTFILES_ROOT"