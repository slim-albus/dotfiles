#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0

usage() {
    cat <<'EOF'
Usage: ./install-packages.sh [--dry-run]

Install the packages listed in packages/<package-manager>.txt. The script
detects apt or dnf and uses sudo for package-manager operations. Git is
required for the dotfiles setup; other packages are optional conveniences.
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

package_available() {
    local package_manager="$1"
    local package="$2"

    if [[ "$package_manager" == apt ]]; then
        apt-get --simulate install "$package" >/dev/null 2>&1
    else
        dnf list "$package" >/dev/null 2>&1
    fi
}

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

# Select the manifest from the package manager available on this machine.
if command -v apt-get >/dev/null 2>&1; then
    package_manager=apt
elif command -v dnf >/dev/null 2>&1; then
    package_manager=dnf
else
    printf 'No supported package manager found. Install apt or dnf first.\n' >&2
    exit 1
fi

package_file="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/packages/$package_manager.txt"
if [[ ! -f "$package_file" ]]; then
    printf 'Package list not found: %s\n' "$package_file" >&2
    exit 1
fi

mapfile -t requested_packages < <(
    sed -e 's/\r$//' -e 's/[[:space:]]*#.*//' -e '/^[[:space:]]*$/d' "$package_file"
)

if ((${#requested_packages[@]} == 0)); then
    printf 'Package list is empty: %s\n' "$package_file" >&2
    exit 1
fi

required_packages=(git)
optional_packages=()
for package in "${requested_packages[@]}"; do
    if [[ "$package" == git ]]; then
        continue
    fi
    optional_packages+=("$package")
done

# Only dependencies required by the setup scripts can stop installation.
if [[ "$package_manager" == apt ]]; then
    run sudo apt-get update
fi

for package in "${required_packages[@]}"; do
    if (( DRY_RUN )) || package_available "$package_manager" "$package"; then
        run sudo "$package_manager" install -y "$package"
    else
        printf 'Required package unavailable from %s repositories: %s\n' "$package_manager" "$package" >&2
        exit 1
    fi
done

for package in "${optional_packages[@]}"; do
    if (( DRY_RUN )); then
        run sudo "$package_manager" install -y "$package"
    elif package_available "$package_manager" "$package"; then
        if ! sudo "$package_manager" install -y "$package"; then
            printf 'Skipping optional package after install failure: %s\n' "$package" >&2
        fi
    else
        printf 'Skipping unavailable optional package: %s\n' "$package" >&2
    fi
done

printf 'Packages installed with %s.\n' "$package_manager"