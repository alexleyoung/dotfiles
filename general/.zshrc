# ─────────────────────────────────────────────────────────────
# tmux initialization
# ─────────────────────────────────────────────────────────────
if command -v tmux >/dev/null 2>&1; then
  if [ -z "$TMUX" ]; then
    tmux attach-session -t misc || tmux new-session -s misc
  fi
fi

# ─────────────────────────────────────────────────────────────
# starship
# ─────────────────────────────────────────────────────────────

eval "$(starship init zsh)"

# ─────────────────────────────────────────────────────────────
# aliases
# ─────────────────────────────────────────────────────────────

# misc
alias c="clear"
alias e="exit"

# git
alias gt="git"
alias gc="git commit"
alias gaa="git add ."
alias gs="git status -s -v"
alias gcm='git commit -m'
alias gp='git push'
alias gpu='git pull'
alias glog='git log --oneline --graph --all'

# lazygit
alias lg="lazygit"

# eza
alias ls="eza --no-filesize --color=always --icons=always --no-user" 

# kitty icat
alias icat="kitten icat"

# ─────────────────────────────────────────────────────────────
# tooling / CLI stuff
# ─────────────────────────────────────────────────────────────
# zoxide (smart directory jumping)
eval "$(zoxide init zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# go cli
export PATH=$PATH:/usr/local/go/bin

# scripts
export PATH=$PATH:$HOME/bin

# opam
# eval `opam config env`

exec fish
