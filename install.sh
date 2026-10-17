#!/usr/bin/env bash
# ============================================================
# Dotfiles Configuration Installer (Linux/WSL)
# ============================================================
set -euo pipefail

DOTFILES_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
FORCE=0
LOG_FILE=''

# ANSI Colors
c_cyan='\033[0;36m'
c_green='\033[0;32m'
c_yellow='\033[1;33m'
c_red='\033[0;31m'
c_magenta='\033[0;35m'
c_white='\033[0;37m'
c_gray='\033[0;90m'
c_reset='\033[0m'

usage() {
    cat <<EOF
Usage: ./install.sh [OPTIONS]

Options:
  --dry-run       Preview actions without making changes
  --force         Force re-linking configuration files
  --log FILE      Write transcript to log file
  -h, --help      Show this help message
EOF
}

step_header() {
    printf "\n=== %s ===\n" "$1"
}

status_ok() {
    printf "  [${c_green}  OK  ${c_reset}] %s\n" "$1"
}

status_skip() {
    printf "  [${c_cyan} SKIP ${c_reset}] %s\n" "$1"
}

status_warn() {
    printf "  [${c_yellow} WARN ${c_reset}] %s\n" "$1"
}

status_fail() {
    printf "  [${c_red} FAIL ${c_reset}] %s\n" "$1"
}

status_info() {
    printf "  [${c_cyan} INFO ${c_reset}] %s\n" "$1"
}

status_dryrun() {
    printf "  [${c_magenta}DRY-RUN${c_reset}] %s\n" "$1"
}

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --force) FORCE=1 ;;
        --log)
            (($# > 1)) || { printf '%s requires a file path.\n' "$1" >&2; exit 2; }
            LOG_FILE="$2"
            shift
            ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if [[ -n "$LOG_FILE" ]]; then
    mkdir -p -- "$(dirname -- "$LOG_FILE")"
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

if [[ "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* ]]; then
    printf 'Error: On Windows, run windows/install.ps1 from PowerShell.\n' >&2
    exit 1
fi

printf "\n  ${c_cyan}========================================================${c_reset}\n"
printf "  ${c_cyan}             Dotfiles Unix/Linux Installer              ${c_reset}\n"
printf "  ${c_cyan}========================================================${c_reset}\n"
printf "  ${c_gray}Source Directory: %s${c_reset}\n" "$DOTFILES_ROOT"
if (( DRY_RUN )); then
    printf "  ${c_magenta}Mode            : PREVIEW ONLY (--dry-run)${c_reset}\n"
fi

# ------------------------------------------------------------
# Step 1: Verify Prerequisites
# ------------------------------------------------------------
step_header "Step [1/4]: Checking Prerequisites"

missing_tools=()
for tool in git bash; do
    if command -v "$tool" >/dev/null 2>&1; then
        status_ok "Found required tool: $tool"
    else
        missing_tools+=("$tool")
    fi
done

if ((${#missing_tools[@]})); then
    for tool in "${missing_tools[@]}"; do
        status_fail "Missing required tool: $tool"
    done
    printf 'Please install missing tools using ./install-packages.sh first.\n' >&2
    exit 1
fi

# ------------------------------------------------------------
# Step 2: Link Configuration Files
# ------------------------------------------------------------
step_header "Step [2/4]: Linking Shared Configurations"

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"

link_config_file() {
    local source="$1"
    local target="$2"
    local name="$3"

    if (( DRY_RUN )); then
        status_dryrun "ln -s $source -> $target"
        return 0
    fi

    mkdir -p -- "$(dirname -- "$target")"

    if [[ -e "$target" || -L "$target" ]]; then
        if [[ "$target" -ef "$source" ]] && (( ! FORCE )); then
            status_skip "Already linked: $name"
            return 0
        fi

        # Backup existing target
        local timestamp
        timestamp="$(date +%Y%m%d%H%M%S)"
        local backup="${target}.dotfiles-backup.${timestamp}"
        mv -f -- "$target" "$backup"
        status_info "Backed up existing $name to $backup"
    fi

    ln -s "$source" "$target"
    status_ok "Linked $name -> $target"
}

link_config_file "$DOTFILES_ROOT/shared/starship.toml" "$config_dir/starship.toml" "Starship Prompt"
link_config_file "$DOTFILES_ROOT/shared/git/config" "$config_dir/git/config" "Git Config"
link_config_file "$DOTFILES_ROOT/shared/git/ignore" "$config_dir/git/ignore" "Git Global Ignore"
link_config_file "$DOTFILES_ROOT/shared/tmux/tmux.conf" "$config_dir/tmux/tmux.conf" "tmux Config"
link_config_file "$DOTFILES_ROOT/shared/fastfetch/config.jsonc" "$config_dir/fastfetch/config.jsonc" "Fastfetch Config"
link_config_file "$DOTFILES_ROOT/shared/micro/settings.json" "$config_dir/micro/settings.json" "Micro Editor Config"

# ------------------------------------------------------------
# Step 3: Setup Oh My Zsh & Shell Plugins
# ------------------------------------------------------------
step_header "Step [3/4]: Shell Environment & Plugins"

clone_or_skip() {
    local repo="$1"
    local dest="$2"
    local desc="$3"

    if [[ -d "$dest/.git" ]]; then
        status_skip "$desc is already installed"
        return 0
    fi

    if (( DRY_RUN )); then
        status_dryrun "git clone $repo -> $dest"
        return 0
    fi

    mkdir -p -- "$(dirname -- "$dest")"
    if git clone --depth=1 "$repo" "$dest" >/dev/null 2>&1; then
        status_ok "Installed $desc"
    else
        status_warn "Could not clone $desc (skipping optional plugin)"
    fi
}

if command -v zsh >/dev/null 2>&1; then
    oh_my_zsh_dir="${ZSH:-$HOME/.oh-my-zsh}"
    custom_dir="$oh_my_zsh_dir/custom"

    clone_or_skip "https://github.com/ohmyzsh/ohmyzsh.git" "$oh_my_zsh_dir" "Oh My Zsh"
    clone_or_skip "https://github.com/zsh-users/zsh-autosuggestions.git" "$custom_dir/plugins/zsh-autosuggestions" "zsh-autosuggestions"
    clone_or_skip "https://github.com/marlonrichert/zsh-autocomplete.git" "$custom_dir/plugins/zsh-autocomplete" "zsh-autocomplete"
else
    status_info "Zsh is not installed; skipping Oh My Zsh setup"
fi

# Register startup sources
register_startup() {
    local file="$1"
    local entry="$2"
    local name="$3"

    if (( DRY_RUN )); then
        status_dryrun "Register startup line in $file"
        return 0
    fi

    touch "$file"
    if grep -Fqx "$entry" "$file" 2>/dev/null; then
        status_skip "Startup line already present in $name"
    else
        printf '\n# dotfiles: load shell configuration\n%s\n' "$entry" >> "$file"
        status_ok "Added startup line to $name"
    fi
}

register_startup "$HOME/.bashrc" "source \"$DOTFILES_ROOT/linux/bashrc\"" "~/.bashrc"
if command -v zsh >/dev/null 2>&1; then
    register_startup "$HOME/.zshrc" "source \"$DOTFILES_ROOT/linux/zshrc\"" "~/.zshrc"
fi

# ------------------------------------------------------------
# Step 4: Verification & Doctor
# ------------------------------------------------------------
step_header "Step [4/4]: Verification"

if (( ! DRY_RUN )); then
    source "$DOTFILES_ROOT/linux/functions.sh"
    doctor || true
else
    status_dryrun "Doctor verification skipped in dry-run mode"
fi

printf "\n  ${c_green}========================================================${c_reset}\n"
printf "  ${c_green}           Dotfiles Setup Completed Successfully!       ${c_reset}\n"
printf "  ${c_green}========================================================${c_reset}\n"
printf "  ${c_gray}Next steps:${c_reset}\n"
printf "    1. Restart your terminal or run: ${c_white}reload${c_reset}\n"
printf "    2. Run ${c_white}dots${c_reset} anytime for your command reference & shortcuts\n"
printf "    3. Run ${c_white}dots doctor${c_reset} to verify health\n\n"