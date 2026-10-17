#!/usr/bin/env bash
# ============================================================
# Package Manifest Installer (Linux/WSL)
# ============================================================
set -euo pipefail

DRY_RUN=0
INSTALL_MODE=full
FORCE=0
LOG_FILE=''

# ANSI Colors
c_cyan='\033[0;36m'
c_green='\033[0;32m'
c_yellow='\033[1;33m'
c_red='\033[0;31m'
c_magenta='\033[0;35m'
c_gray='\033[0;90m'
c_reset='\033[0m'

usage() {
    cat <<EOF
Usage: ./install-packages.sh [OPTIONS]

Options:
  --dry-run       Preview package installations without making changes
  --minimal       Install only essential baseline packages (git, zsh, curl, micro, starship)
  --full          Install all packages from manifest (default)
  --force         Force re-installing already installed packages
  --log FILE      Append output transcript to log file
  -h, --help      Show this help message
EOF
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
        --minimal) INSTALL_MODE=minimal ;;
        --full) INSTALL_MODE=full ;;
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

# Detect Package Manager
if command -v dnf >/dev/null 2>&1; then
    package_manager=dnf
elif command -v apt-get >/dev/null 2>&1; then
    package_manager=apt
else
    printf 'No supported package manager found (expected apt or dnf).\n' >&2
    exit 1
fi

package_file="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/packages/$package_manager.txt"
if [[ ! -f "$package_file" ]]; then
    printf 'Package manifest not found: %s\n' "$package_file" >&2
    exit 1
fi

mapfile -t raw_packages < <(
    sed -e 's/\r$//' -e 's/[[:space:]]*#.*//' -e '/^[[:space:]]*$/d' "$package_file"
)

if ((${#raw_packages[@]} == 0)); then
    printf 'Package manifest is empty: %s\n' "$package_file" >&2
    exit 1
fi

# Filter packages if --minimal
if [[ "$INSTALL_MODE" == minimal ]]; then
    minimal_whitelist=(git zsh curl micro starship tmux)
    requested_packages=()
    for p in "${raw_packages[@]}"; do
        for w in "${minimal_whitelist[@]}"; do
            if [[ "$p" == "$w" ]]; then
                requested_packages+=("$p")
                break
            fi
        done
    done
else
    requested_packages=("${raw_packages[@]}")
fi

printf "\n  ${c_cyan}========================================================${c_reset}\n"
printf "  ${c_cyan}           Dotfiles Linux Package Installer             ${c_reset}\n"
printf "  ${c_cyan}========================================================${c_reset}\n"
printf "  ${c_gray}Package Manager : %s${c_reset}\n" "$package_manager"
printf "  ${c_gray}Manifest File   : %s${c_reset}\n" "$package_file"
printf "  ${c_gray}Total Packages  : %d${c_reset}\n" "${#requested_packages[@]}"
if [[ "$INSTALL_MODE" == minimal ]]; then
    printf "  ${c_yellow}Mode            : MINIMAL${c_reset}\n"
fi
if (( DRY_RUN )); then
    printf "  ${c_magenta}Execution Mode  : PREVIEW ONLY (--dry-run)${c_reset}\n"
fi

is_package_installed() {
    local pkg="$1"
    if [[ "$package_manager" == apt ]]; then
        dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
    else
        rpm -q "$pkg" >/dev/null 2>&1
    fi
}

total_count=${#requested_packages[@]}
installed_count=0
skipped_count=0
failed_count=0
failed_packages=()

# Pre-refresh apt cache if not dry-run
if (( ! DRY_RUN )) && [[ "$package_manager" == apt ]]; then
    printf "\n  ${c_cyan}Updating apt package index...${c_reset}\n"
    sudo apt-get update -qq || true
fi

printf "\n"
for ((idx=0; idx<total_count; idx++)); do
    pkg="${requested_packages[idx]}"
    counter="$(printf "[%2d/%2d]" "$((idx+1))" "$total_count")"

    # Fast pre-flight check
    if (( ! FORCE )) && is_package_installed "$pkg"; then
        status_skip "$counter Already present: $pkg"
        skipped_count=$((skipped_count + 1))
        continue
    fi

    if (( DRY_RUN )); then
        status_dryrun "$counter sudo $package_manager install -y $pkg"
        skipped_count=$((skipped_count + 1))
        continue
    fi

    status_info "$counter Installing $pkg ..."
    if [[ "$package_manager" == apt ]]; then
        if sudo apt-get install -y "$pkg" >/dev/null 2>&1; then
            status_ok "$counter Successfully installed: $pkg"
            installed_count=$((installed_count + 1))
        else
            status_fail "$counter Failed to install: $pkg"
            failed_count=$((failed_count + 1))
            failed_packages+=("$pkg")
        fi
    else
        if sudo dnf install -y "$pkg" >/dev/null 2>&1; then
            status_ok "$counter Successfully installed: $pkg"
            installed_count=$((installed_count + 1))
        else
            status_fail "$counter Failed to install: $pkg"
            failed_count=$((failed_count + 1))
            failed_packages+=("$pkg")
        fi
    fi
done

# ------------------------------------------------------------
# Summary Report
# ------------------------------------------------------------
printf "\n  ${c_cyan}========================================================${c_reset}\n"
printf "  ${c_cyan}              Package Installation Summary              ${c_reset}\n"
printf "  ${c_cyan}========================================================${c_reset}\n"
printf "  Total in Queue   : %d\n" "$total_count"
printf "  ${c_green}Installed        : %d${c_reset}\n" "$installed_count"
printf "  ${c_cyan}Skipped (Present): %d${c_reset}\n" "$skipped_count"
if (( failed_count > 0 )); then
    printf "  ${c_red}Failed           : %d${c_reset}\n" "$failed_count"
    printf "\n  ${c_red}Failed Packages:${c_reset}\n"
    for failed_pkg in "${failed_packages[@]}"; do
        printf "    - %s\n" "$failed_pkg"
    done
    printf "\n  ${c_gray}Tip: You can retry failed packages individually with: sudo %s install <package>${c_reset}\n" "$package_manager"
else
    printf "  ${c_green}Failed           : 0${c_reset}\n"
fi
printf "  ${c_cyan}========================================================${c_reset}\n\n"