# Navigation, listing, and Git shortcuts.

# ---- Directory Navigation ----
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias '~'='cd ~'
alias docs='cd "$HOME/Documents"'
alias dtop='cd "$HOME/Desktop"'

# ---- Enhanced File Listing ----
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons'
    alias l='eza -l --icons --git'
    alias la='eza -la --icons --git'
    alias ll='eza -la --icons --git'
else
    alias ls='ls --color=auto'
    alias l='ls -lF --color=auto'
    alias la='ls -laF --color=auto'
    alias ll='ls -laF --color=auto'
fi

# ---- Git Shortcuts ----
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpull='git pull'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gsw='git switch'
alias gcp='git cherry-pick'
alias gclean='git clean -fd'
alias gclean-preview='git clean -fdn'
alias groot='cd -- "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"'

# ---- Docker Shortcuts ----
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dlogs='docker logs -f'
alias dexec='docker exec -it'
alias dstop='docker stop'
alias drm='docker rm'

# ---- System Shortcuts ----
alias cls='clear'
alias df='df -h'
alias grep='grep --color=auto'

# ---- Debian/Ubuntu Binary Fallbacks ----
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
fi
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    alias fd='fdfind'
fi

# ---- Cross-Platform Parity Aliases ----
alias project-root='project_root'
alias Show-Tree='treeview'
alias Backup-Item='backup'
alias Get-BigFiles='bigfiles'
alias Show-Path='path'
alias pgrep='psg'
alias ep='${EDITOR:-micro} "$HOME/.bashrc"'