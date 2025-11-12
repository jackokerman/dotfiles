# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles repository managing cross-platform shell configurations and macOS-specific system settings. The install script creates symlinks from this repository to appropriate locations in the home directory and `~/.config/`, allowing version-controlled configuration files while supporting machine-specific overrides.

## Installation Commands

```bash
# Create symlinks for config files
./install.sh link

# Set up shell tools (Zap plugin manager, fzf, bat)
./install.sh shell

# Install Homebrew packages from Brewfile (macOS only)
./install.sh brew

# Configure macOS system preferences (macOS only)
./install.sh macos

# Run all setup steps
./install.sh all

# Create symlinks from a custom directory (dotfiles overlay)
./install.sh link-dir /path/to/config/directory
```

## Configuration Architecture

### Symlink Strategy

The install script uses `create_symlinks_from_dir()` to recursively create symlinks while preserving directory structure. Key behavior:

- Files in `zsh/` → `~/` (e.g., `zsh/.zshrc` → `~/.zshrc`)
- Directories in `config/` → `~/.config/` (e.g., `config/hammerspoon/` → `~/.config/hammerspoon/`)
- Existing symlinks are skipped; existing non-symlink files trigger warnings
- Version control files (`.git`, `.gitignore`, `README.md`) are excluded from symlinking

### Machine-Specific Configuration

Configuration files support local overrides that are excluded from version control:

- **Git**: `~/.gitconfig-local` included by `~/.config/git/config`
- **Zsh**: `~/.zshrc-local` sourced by `~/.zshrc`
- **Hammerspoon**: `~/.config/hammerspoon/init-local.lua` loaded by `init.lua`

Use convenience commands:
```bash
# Edit machine-specific git settings
git config-local user.email "your-email@example.com"

# Edit shared git settings (in version control)
git config-shared alias.st "status"
```

### Karabiner-Elements Configuration

The `karabiner-config.ts` file is a Deno TypeScript script that generates Karabiner-Elements configuration programmatically. Currently configured to disable all keys on Apple Magic Keyboard (product_id: 666) except Touch ID.

**To regenerate configuration:**
```bash
deno run --allow-env --allow-read --allow-write karabiner-config.ts
```

This is automatically run by `./install.sh macos` or `./install.sh all`.

## Key Application Configurations

### AeroSpace (Window Manager)

Configuration: `config/aerospace/aerospace.toml`

**Workspace model:**
- Numbered workspaces: 1-9
- Named workspaces for specific app categories:
  - `B` (Browser) - Primary browser
  - `M` (Messaging) - Slack, Gmail, Calendar
  - `N` (Notes) - Obsidian and documentation
  - `P` (Personal) - Personal browser profile
  - `T` (Tasks) - Godspeed task manager
  - `Z` (Zoom) - Video conferencing (auto-assigned via `on-window-detected`)

**Key bindings:**
- `alt-hjkl` for vim-style focus movement
- `alt-shift-hjkl` for moving windows
- `alt-[1-9,b,m,n,p,t,z]` for workspace switching
- `alt-shift-[1-9,b,m,n,p,t,z]` for moving windows to workspaces
- `alt-f` for fullscreen
- Service mode (`alt-shift-;`) for advanced operations

### Hammerspoon (Desktop Automation)

Configuration: `config/hammerspoon/init.lua`

**Custom Spoons:**
- **RichLinkCopy** (`cmd-shift-c`): Enhanced link copying functionality
- **SmartLinkManager**: Routes URLs to different Chrome profiles based on patterns
  - Wraps URLDispatcher spoon for Chrome profile routing
  - Methods: `addChromeUrlPattern(pattern, profileName)`, `addUrlPattern(pattern, browserFunction)`
  - Lists available Chrome profiles on startup

**Configuration pattern:**
Use `init-local.lua` for machine-specific Hammerspoon configuration (e.g., URL routing patterns).

### Zsh

Configuration: `zsh/.zshrc`

**Plugin manager:** Zap (installed to `~/.local/share/zap`)

**Key plugins:**
- powerlevel10k (theme)
- zsh-z (directory jumping)
- fzf-tab (fuzzy completion)
- zsh-syntax-highlighting, zsh-autosuggestions, zsh-history-substring-search

**Aliases:** Sourced from `~/.aliases` (not in this repository)

### Git

Configuration: `config/git/config`

**Custom aliases:**
- `git squash -m "message" <count|hash>` - Squash commits (supports both count-based and hash-based)
- `git config-shared` - Edit shared config (in version control)
- `git config-local` - Edit local config (machine-specific)

**Settings:**
- Default branch: main
- Auto-prune on fetch
- Rebase on pull
- Auto-setup remote on push

## macOS System Preferences

The `macos` script configures extensive system preferences using `defaults write`. Key customizations:

- Disable animations and transparency
- Fast keyboard repeat rates (InitialKeyRepeat: 10, KeyRepeat: 2)
- Always show hidden files in Finder
- Auto-hide Dock with zero delay
- Disable smart quotes/dashes/autocorrect
- Safari developer settings enabled
- Sets Hammerspoon config location to `~/.config/hammerspoon/init.lua`

**Important:** Changes require logout/restart to take effect.

## Package Management

`Brewfile` defines Homebrew packages and applications:

**Applications (macOS only):**
bartender, hammerspoon, iterm2, keepingyouawake, kitty, raycast, spotify, shottr, karabiner-elements, aerospace

**CLI Tools:**
bat, eza, fd, fzf, git, jq, python, wget, zsh, deno

## Development Notes

- When modifying install script logic, test symlink creation carefully to avoid breaking existing installations
- The install script uses color-coded output functions: `title()`, `error()`, `warning()`, `info()`, `success()`
- Karabiner configuration uses the karabinerts Deno library (v1.30.0)
- SmartLinkManager expects URLDispatcher to be loaded before adding patterns
