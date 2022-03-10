# Editing
alias aliases='$EDITOR ~/zsh/aliases.zsh'
alias zshrc='$EDITOR ~/.zshrc'

# Git
alias gst='git status'
alias gco='git checkout'
alias gb='git branch'
alias gcaa="git add --all && git commit --amend --no-edit"
alias gcaae="git add --all && git commit --amend"
alias gcb='git checkout -b'
alias gcd='git checkout develop && git pull'
alias gre='git restore'
# Discard all unstaged changes
alias gnope='git restore .'
alias gpl='git pull'
alias gps='git push'
alias gpsf="git push --force-with-lease"
# Push and set the upstream to name of the local branch
alias gpsup='git push -u origin HEAD'
# Add all untracked files and commit with message
alias gcam='git add --all && git commit -m'
# Commit with message
alias gcm='git commit -m'
# Rename the current branch
alias grnm='git branch -m'
# Delete the current branch
alias gbd='git branch -D'

# LSD
# alias ls='lsd'
alias ll='ls -l'
alias l1='ls -1'
alias la='ls -a'
alias lal='ls -la'
alias lla='ls -la'
alias lt='ls --tree'

# Brew
alias br="brew"
alias brci="brew install --cask"
alias bri="brew install"
alias brs="brew search"

# Misc
alias reload='$SHELL -l'
alias c='clear'
alias cl='clear'

