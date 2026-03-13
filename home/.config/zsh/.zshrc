# Source system-managed ~/.zshrc if present (e.g., Chef-managed on work machines).
# Only source if it's a real file (not a symlink to our config). The guard variable
# prevents infinite recursion when ~/.zshrc tries to source our old path.
if [[ -z "$_DOTFILES_ZSHRC_LOADED" && -f ~/.zshrc && ! -L ~/.zshrc ]]; then
  _DOTFILES_ZSHRC_LOADED=1
  source ~/.zshrc 2>/dev/null || true
fi

# Remind once per session if dotfiles are stale.
# Runs above instant prompt to avoid p10k's console output warning.
command -v dotty >/dev/null 2>&1 && dotty check

# Enable Powerlevel10k instant prompt. Should stay close to the top of .zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Plugins (clones missing plugins in parallel, then sources in order)
source $ZDOTDIR/.zetch.zsh

plugins=(
  romkatv/powerlevel10k                    # shell prompt with instant prompt
  zsh-users/zsh-completions                # additional completion definitions
  Aloxaf/fzf-tab                           # fzf-powered tab completion
  zsh-users/zsh-autosuggestions            # fish-like inline suggestions
  trystan2k/zsh-tab-title                  # dynamic terminal tab titles
  zsh-users/zsh-syntax-highlighting        # command syntax highlighting
  zsh-users/zsh-history-substring-search   # history search with up/down arrows
)
zetch ensure $plugins

# Source plugins in order: prompt first, then compinit, then everything else.
# fzf-tab must load after compinit. syntax-highlighting before history-substring-search.
zetch romkatv/powerlevel10k

# Completions: each directory below provides _completion functions. Adding them
# to fpath makes them discoverable, then compinit compiles and registers them.
fpath_dirs=(
  $HOME/.local/share/zsh/site-functions    # XDG location (dotty, devvy, etc.)
  /opt/homebrew/share/zsh/site-functions   # Homebrew-installed completions
  $ZPLUGINDIR/zsh-completions/src          # zsh-users/zsh-completions plugin
)
zetch compinit $fpath_dirs

zetch Aloxaf/fzf-tab
zetch zsh-users/zsh-autosuggestions
zetch trystan2k/zsh-tab-title
zetch zsh-users/zsh-syntax-highlighting
zetch zsh-users/zsh-history-substring-search

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
        # APT installation (Linux devboxes)
        source /usr/share/doc/fzf/examples/key-bindings.zsh
        source /usr/share/doc/fzf/examples/completion.zsh
    else
        # Homebrew or other installation
        source <(fzf --zsh)
    fi
fi

# bun completions (sourced, not fpath-based — bun uses dynamic compdef)
if [[ -s "$HOME/.bun/_bun" ]]; then
  source "$HOME/.bun/_bun"
fi
