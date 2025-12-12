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

# Zap plugin manager
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

plug "romkatv/powerlevel10k"
plug "Aloxaf/fzf-tab"
plug "zsh-users/zsh-completions"
plug "zsh-users/zsh-syntax-highlighting"
plug "zsh-users/zsh-history-substring-search"
plug "zsh-users/zsh-autosuggestions"
plug "wintermi/zsh-brew"
plug "trystan2k/zsh-tab-title"

# Load and initialize completion system
autoload -Uz compinit
compinit

# Initialize zoxide for smarter directory jumping
eval "$(zoxide init zsh)"

# Aliases
source $HOME/.aliases

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Load local configuration if it exists, i.e. machine-specific config.
[[ ! -f ~/.zshrc-local ]] || source ~/.zshrc-local

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
