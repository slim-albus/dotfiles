# Prompt integration (Starship with clean fallback prompt)

if command -v starship >/dev/null 2>&1; then
    if [[ -n "${BASH_VERSION:-}" ]]; then
        eval "$(starship init bash)"
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        eval "$(starship init zsh)"
    fi
else
    # Minimal, colorized fallback prompt if Starship is not installed
    if [[ -n "${BASH_VERSION:-}" ]]; then
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        PROMPT='%F{green}%n@%m%f:%F{cyan}%~%f%# '
    fi
fi