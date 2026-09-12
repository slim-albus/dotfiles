#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0

usage() {
    cat <<'EOF'
Usage: ./install-packages.sh [--dry-run]

Install the packages listed in packages/<package-manager>.txt. The script
detects apt or dnf and uses sudo for package-manager operations. Packages
unavailable in the configured repositories are skipped with a warning.
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

packages=()
# Filter comments and check package availability before installing.
if [[ "$package_manager" == apt ]]; then
    run sudo apt-get update
    for package in "${requested_packages[@]}"; do
        if (( DRY_RUN )) || apt-cache show "$package" >/dev/null 2>&1; then
            packages+=("$package")
        else
            log "skipping unavailable apt package: $package"
        fi
    done
    run sudo apt-get install -y "${packages[@]}"
else
    for package in "${requested_packages[@]}"; do
        if (( DRY_RUN )) || dnf list --available "$package" >/dev/null 2>&1; then
            packages+=("$package")
        else
            log "skipping unavailable dnf package: $package"
        fi
    done
    run sudo dnf install -y "${packages[@]}"
fi

printf 'Packages installed with %s.\n' "$package_manager"