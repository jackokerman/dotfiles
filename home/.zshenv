# Bootstrap for ZDOTDIR - this file must live in $HOME for zsh to find it.
# All actual zsh configuration lives in ~/.config/zsh/
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
source "$ZDOTDIR/.zshenv"
