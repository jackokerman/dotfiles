# Environment Variables

# Set `EDITOR` to Cursor if it's installed, otherwise VS Code, otherwise use default
if command -v cursor >/dev/null; then
  export EDITOR="cursor --wait --new-window"
elif command -v code >/dev/null; then
  export EDITOR="code --wait --new-window"
fi

# Nightfly theme for fzf, upstream: github.com/bluz71/vim-nightfly-colors
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
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

# Skip the global compinit which conflicts with setup on linux machines.
skip_global_compinit=1

# Path
export PATH="$HOME/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
