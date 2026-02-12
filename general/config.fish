function fish_prompt -d "Write out the prompt"
    # This shows up as USER@HOST /home/user/ >, with the directory colored
    # $USER and $hostname are set by fish, so you can just use them
    # instead of using `whoami` and `hostname`
    printf '%s@%s %s%s%s > ' $USER $hostname \
        (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
end

if status is-interactive # Commands to run in interactive sessions can go here
    # No greeting
    set fish_greeting

    # Use starship
    starship init fish | source
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    zoxide init fish | source

    # Aliases
    alias pamcan pacman
    alias ls 'eza --icons'
    alias lsa 'eza -a --icons'
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias q 'qs -c ii'

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

    # kitty icat
    alias icat="kitten icat"

    if not set -q TMUX
        exec tmux new-session -A -s misc
    end
end
