# Environment Variables

export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Keep mutable zsh state out of the repo-backed config tree.
export ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-$XDG_CACHE_HOME/zsh}"
export ZSH_STATE_DIR="${ZSH_STATE_DIR:-$XDG_STATE_HOME/zsh}"
if [[ -o interactive ]]; then
  mkdir -p "$ZSH_CACHE_DIR/.zcompcache" "$ZSH_STATE_DIR"
fi

# Initialize history sizing before zsh imports history for interactive shells.
export HISTSIZE="${HISTSIZE:-2000}"
export SAVEHIST="${SAVEHIST:-1000}"
export HISTFILE="$ZSH_STATE_DIR/history"
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/.zcompdump"
export ZSH_COMPCACHE_DIR="$ZSH_CACHE_DIR/.zcompcache"

# Disable macOS Terminal shell session files in ~/.zsh_sessions.
export SHELL_SESSIONS_DISABLE=1

# Set `EDITOR` to Neovim if it's installed, otherwise use the default.
if command -v nvim >/dev/null; then
  export EDITOR="nvim"
fi

# Nightfly theme for fzf, upstream: github.com/bluz71/vim-nightfly-colors
if [[ "${FZF_DEFAULT_OPTS-}" != *"--color bg:#011627"* ]]; then
  export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} \
  --color bg:#011627 \
  --color bg+:#0e293f \
  --color border:#2c3043 \
  --color fg:#acb4c2 \
  --color fg+:#d6deeb \
  --color gutter:#0e293f \
  --color header:#82aaff \
  --color hl+:#f78c6c \
  --color hl:#f78c6c \
  --color info:#ecc48d \
  --color marker:#f78c6c \
  --color pointer:#ff5874 \
  --color prompt:#82aaff \
  --color spinner:#21c7a8
"
fi

# Enable true color detection for tools like bat, delta, and Claude Code.
# Ghostty supports true color natively but some tools check this variable.
export COLORTERM="truecolor"

# Skip the global compinit which conflicts with setup on linux machines.
skip_global_compinit=1

# Path
typeset -gU path PATH
path=("$HOME/bin" "${path[@]}")
path=("/opt/homebrew/bin" "${path[@]}")
path=("$HOME/.local/bin" "${path[@]}")
[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" "${path[@]}")
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
[[ -d "$BUN_INSTALL/bin" ]] && path=("$BUN_INSTALL/bin" "${path[@]}")
[[ -d "$HOME/go/bin" ]] && path=("$HOME/go/bin" "${path[@]}")
[[ -d "$HOME/.dotty/bin" ]] && path=("$HOME/.dotty/bin" "${path[@]}")
export PATH

# Homebrew strips non-HOMEBREW_ env vars before evaluating Brewfiles.
export HOMEBREW_DOTFILES_ENV="${HOMEBREW_DOTFILES_ENV:-personal}"

# Aerospace window arrangement: "APP_NAME|FILTER|WORKSPACE" comma-separated
export AEROSPACE_ARRANGEMENTS="\
Google Chrome||B,\
Arc||B,\
Calendar||C,\
Messages||M,\
Obsidian||N,\
Godspeed||T,\
Discord||D"

# Source local environment overrides if they exist (e.g., work-specific config)
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
