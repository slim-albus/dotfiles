# Environment variables and PATH additions.

export EDITOR='micro'
export VISUAL='micro'
export PAGER='less'
unset GIT_EDITOR GIT_PAGER
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml}"

path_add() {
    case ":${PATH}:" in
        *:"$1":*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}

for path_entry in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin" "$HOME/bin"; do
    [[ -d "$path_entry" ]] && path_add "$path_entry"
done
export PATH

unset -f path_add