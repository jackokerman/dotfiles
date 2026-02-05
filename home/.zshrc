# Exit early if COMPOSER_NO_INTERACTION is set. This is needed to allow Cursor
# to run terminal commands without hanging, as prompt customizations can cause
# issues in non-interactive shells.
if [[ -n "$COMPOSER_NO_INTERACTION" ]]; then
  return 0
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Start of plugin manager

source $HOME/.zfetch.zsh

zfetch "romkatv/powerlevel10k" "powerlevel10k.zsh-theme"

# completions (order matters: fpath before compinit, fzf-tab after)
zfetch completions
if ! (( $+functions[compdef] )); then
  # Only run compinit if not already initialized. Some environments require
  # sourcing a file that calls compinit before this one runs, and calling it
  # twice resets completion registrations.
  autoload -Uz compinit
  compinit
fi
zfetch "Aloxaf/fzf-tab"

# plugins
zfetch "zsh-users/zsh-syntax-highlighting"
zfetch "zsh-users/zsh-history-substring-search"
zfetch "zsh-users/zsh-autosuggestions"
zfetch "wintermi/zsh-brew"
zfetch "trystan2k/zsh-tab-title"

# End of plugin manager

# initialize zoxide for smarter directory jumping (if available)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Aliases
source $HOME/.aliases

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Load local configuration if it exists, i.e. machine-specific config.
[[ ! -f ~/.zshrc.local ]] || source ~/.zshrc.local

# Setup fzf
if command -v fzf >/dev/null 2>&1; then
    if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
        # APT installation
        source /usr/share/doc/fzf/examples/key-bindings.zsh
        source /usr/share/doc/fzf/examples/completion.zsh
    elif [ -f ~/.fzf.zsh ]; then
        # Homebrew installation
        source ~/.fzf.zsh
    fi
fi
