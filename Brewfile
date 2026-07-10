# Taps
tap "oven-sh/bun"                   # preferred JavaScript runtime

def executable_paths(command)
  paths = []
  search_path = [
    ENV.fetch("PATH", ""),
    ENV.fetch("HOMEBREW_DOTFILES_HOST_PATH", ""),
  ].join(File::PATH_SEPARATOR)

  search_path.split(File::PATH_SEPARATOR).each do |dir|
    path = File.join(dir, command)
    next unless File.file?(path) && File.executable?(path)

    paths << begin
      File.realpath(path)
    rescue StandardError
      path
    end
  end

  paths.uniq
end

def homebrew_managed_path?(path)
  prefix = ENV["HOMEBREW_PREFIX"].to_s
  return false if prefix.empty?

  real_prefix = begin
    File.realpath(prefix)
  rescue StandardError
    prefix
  end

  path == real_prefix || path.start_with?("#{real_prefix}/")
end

def host_provides_command?(command)
  executable_paths(command).any? { |path| !homebrew_managed_path?(path) }
end

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
brew "gh" unless host_provides_command?("gh")
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
  brew "git"                        # git version control (latest)
  brew "node"                       # broad JS CLI compatibility
end
