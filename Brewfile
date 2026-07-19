require_relative "scripts/brewfile_helpers"

# Taps
tap "agavra/tap"                    # terminal code review TUI
tap "oven-sh/bun"                   # preferred JavaScript runtime

# Applications
if OS.mac?
  cask "1password"                  # password manager
  cask "nikitabobko/tap/aerospace"  # a tiling window manager
  cask "cleanshot"                  # screenshot tool
  cask "ghostty"                    # modern terminal emulator
  cask "hammerspoon"                # desktop automation application
  cask "karabiner-elements"         # keyboard customizer
  cask "keepingyouawake"            # prevent mac from going to sleep
  cask "logi-options+"              # software for Logitech mouse
  cask "obsidian"                   # knowledge base with markdown files
  cask "raycast"                    # spotlight replacement
  cask "spotify"                    # music streaming service

  # Personal applications
  if ENV["HOMEBREW_DOTFILES_ENV"] == "personal"
    cask "claude-code"              # Anthropic coding agent terminal CLI
    cask "codex"                    # OpenAI coding agent terminal CLI
    cask "discord"                  # chat and voice application
    cask "handy"                    # window snapping and management
    cask "visual-studio-code"       # code editor
    cask "zen"                      # firefox-based browser
  end
end

# Packages
brew "bat"                          # a better cat
brew "oven-sh/bun/bun"              # JavaScript runtime
brew "deno"                         # a better node
brew "eza"                          # a better ls
brew "fd"                           # find alternative
brew "fzf"                          # a fuzzy finder
brew "gh" unless host_has?("gh")    # GitHub command-line interface
brew "git-delta"                    # syntax-highlighted git diff pager
brew "glow"                         # markdown renderer for the terminal
brew "jq"                           # parse and work with JSON
brew "neovim"                       # extensible modal editor
brew "node-build"                   # nodenv install definitions
brew "nodenv"                       # Node.js version manager
brew "ripgrep"                      # fast recursive search tool (`rg`)
brew "sesh"                         # smart tmux session manager
brew "television"                   # rich terminal fuzzy finder (`tv`)
brew "tmux"                         # terminal multiplexer
brew "agavra/tap/tuicr"             # terminal code review TUI
brew "wget"                         # internet file retriever
brew "zoxide"                       # smarter cd command (z/zi)
brew "zsh"                          # zsh shell (latest)

# Personal packages
if ENV["HOMEBREW_DOTFILES_ENV"] == "personal"
  brew "git"                        # git version control (latest)
  brew "node"                       # broad JS CLI compatibility
  brew "python"                     # python (latest)
end
