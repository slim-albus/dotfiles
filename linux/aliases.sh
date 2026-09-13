# Navigation, listing, and Git shortcuts.

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias '~'='cd ~'

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons'
    alias l='eza -l --icons --git'
    alias la='eza -la --icons --git'
    alias ll='eza -la --icons --git'
else
    alias l='ls -lF'
    alias la='ls -laF'
    alias ll='ls -laF'
fi

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gsw='git switch'
alias gcp='git cherry-pick'
alias gclean='git clean -fdn'
alias gclean-force='git clean -fd'
alias groot='cd -- "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"'
alias grep='grep --color=auto'

# Docker shortcuts
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dlogs='docker logs -f'
alias dexec='docker exec -it'
alias dstop='docker stop'
alias drm='docker rm'

# Cross-platform clear command
alias cls='clear'