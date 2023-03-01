# Editing
alias zshrc='$EDITOR $HOME/.zshrc'
alias aliases='$EDITOR $HOME/aliases.zsh'

# Git
alias gst='git status'
alias gco='git checkout'
alias gs='git switch'
alias gb='git branch'
alias ga='git add'
alias gap='git add --patch'
alias gaa='git add --all'
alias gc='git commit'
alias gca="git commit --amend --no-edit"
alias gcae="git commit --amend"
alias gcaa='git add --all && git commit --amend --no-edit'
alias gcaae='git add --all && git commit --amend'
alias gcb='git checkout -b'
alias gcd='git checkout develop && git pull'
alias gre='git restore'
alias gres='git restore --staged'
alias grb='git rebase'
# Discard all unstaged changes
alias gnope='git restore . && git clean -fd'
alias gpl='git pull'
alias gps='git push'
alias gpsf='git push --force-with-lease'
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
# Work In Progress commit (alternative to stashing)
alias gwip='git add -A; git commit -m "WIP"'
alias gunwip='git reset HEAD~1'

# Select recent branch interacctively using fzf
alias gbr='git branch --sort=-committerdate | fzf --header "Checkout Recent Branch" --preview "git diff --color=always {1}" --pointer "" | xargs git checkout'
alias gbs='gbr'

# Brew
alias br='brew'
alias brci='brew install --cask'
alias bri='brew install'
alias brs='brew search'
# ls (exa)
alias ls='exa --icons --group-directories-first'
alias ll='ls -l'
alias l1='ls -1'
alias la='ls -a'
alias lal='ls -la'
alias lla='ls -la'
alias lt='ls --tree'

# Misc
alias reload='$SHELL -l'
alias c='clear'
alias cl='clear'
