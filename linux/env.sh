# Environment variables and PATH additions.

export EDITOR="${EDITOR:-micro}"
export VISUAL="${VISUAL:-micro}"
export PAGER="${PAGER:-less}"
unset GIT_EDITOR GIT_PAGER

# Resolve dotfiles root reliably across Bash and Zsh
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    DOTFILES_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
elif [[ -n "${(%):-%N}" ]]; then
    DOTFILES_ROOT="$(cd -- "$(dirname -- "${(%):-%N}")/.." && pwd)"
else
    DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"
fi
export DOTFILES_ROOT

export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$DOTFILES_ROOT/shared/starship.toml}"

path_add() {
    case ":${PATH}:" in
        *:"$1":*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

# Prepend modern tool paths (Bun first, then user locals)
for path_entry in "$HOME/.bun/bin" "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin" "$HOME/bin"; do
    [[ -d "$path_entry" ]] && path_add "$path_entry"
done
export PATH

unset -f path_add