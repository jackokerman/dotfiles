# Taps
tap "oven-sh/bun"                   # preferred JavaScript runtime

# Applications
if OS.mac?
  cask "hammerspoon"                # desktop automation application
  cask "ghostty"                    # modern terminal emulator
  cask "keepingyouawake"            # prevent mac from going to sleep
  cask "raycast"                    # spotlight replacement
  cask "spotify"                    # music streaming service
  cask "karabiner-elements"         # keyboard customizer
  cask "nikitabobko/tap/aerospace"  # a tiling window manager
  cask "cleanshot"                  # screenshot tool
  cask "logi-options+"              # software for Logitech mouse
  cask "obsidian"                   # knowledge base with markdown files
  cask "1password"                  # password manager

  if ENV["HOMEBREW_DOTFILES_ENV"] == "personal"
    # Personal applications
    cask "visual-studio-code"       # code editor
    cask "codex"                    # OpenAI coding agent terminal CLI
    cask "claude-code"              # Anthropic coding agent terminal CLI
    cask "handy"                    # window snapping and management
    cask "discord"                  # chat and voice application
    cask "zen"                      # firefox-based browser
  end
end

# Packages
brew "bat"                          # a better cat
brew "eza"                          # a better ls
brew "fd"                           # find alternative
brew "fzf"                          # a fuzzy finder
brew "git-delta"                    # syntax-highlighted git diff pager
brew "glow"                         # markdown renderer for the terminal
brew "hunk"                         # review-first terminal diff viewer
brew "jq"                           # parse and work with JSON
brew "neovim"                       # extensible modal editor
brew "python"                       # python (latest)
brew "ripgrep"                      # fast recursive search tool (`rg`)
brew "wget"                         # internet file retriever
brew "zsh"                          # zsh shell (latest)
brew "deno"                         # a better node
brew "nodenv"                       # Node.js version manager
brew "node-build"                   # nodenv install definitions
brew "oven-sh/bun/bun"              # JavaScript runtime
brew "tmux"                         # terminal multiplexer
brew "sesh"                         # smart tmux session manager
brew "television"                   # rich terminal fuzzy finder (`tv`)
brew "zoxide"                       # smarter cd command (z/zi)

if ENV["HOMEBREW_DOTFILES_ENV"] == "personal"
  # Personal packages
  brew "gh"                         # GitHub CLI
  brew "git"                        # git version control (latest)
  brew "node"                       # broad JS CLI compatibility
end
