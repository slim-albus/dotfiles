# Prompt integration.

if command -v starship >/dev/null 2>&1; then
    if [[ -n "${BASH_VERSION:-}" ]]; then
        eval "$(starship init bash)"
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        eval "$(starship init zsh)"
    fi
fi