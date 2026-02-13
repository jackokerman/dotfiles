# Source system-managed ~/.zshrc if present (e.g., Chef-managed on work machines).
# Only source if it's a real file (not a symlink to our config). The guard variable
# prevents infinite recursion when ~/.zshrc tries to source our old path.
if [[ -z "$_DOTFILES_ZSHRC_LOADED" && -f ~/.zshrc && ! -L ~/.zshrc ]]; then
  _DOTFILES_ZSHRC_LOADED=1
  source ~/.zshrc 2>/dev/null || true
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of .zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Start of plugin manager

source $ZDOTDIR/.zfetch.zsh

zfetch "romkatv/powerlevel10k" "powerlevel10k.zsh-theme"

# completions
zfetch fpath "$HOME/.dotty/completions"
zfetch completions
if ! (( $+functions[_complete] )); then
  # Only run compinit if not already initialized. Calling compinit twice
  # resets completion registrations.
  autoload -Uz compinit
  compinit
fi

# fzf-tab needs to be loaded after compinit, before other plugins that use completion.
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
source $ZDOTDIR/.aliases

# To customize prompt, run `p10k configure` or edit $ZDOTDIR/.p10k.zsh.
[[ ! -f $ZDOTDIR/.p10k.zsh ]] || source $ZDOTDIR/.p10k.zsh

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
