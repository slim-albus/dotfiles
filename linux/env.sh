# Environment variables and PATH additions.

export EDITOR="${EDITOR:-micro}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml}"

path_add() {
    case ":${PATH}:" in
        *:"$1":*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

for path in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin" "$HOME/bin"; do
    [[ -d "$path" ]] && path_add "$path"
done
export PATH

unset -f path_add