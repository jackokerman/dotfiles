# Dotfiles

My personal dotfiles. Includes cross-platform shell configurations and macOS-specific system settings.

## Installation

1. Clone this repository:

```bash
git clone https://github.com/jackokerman/dotfiles.git
cd dotfiles
```

2. Run the install script:

```bash
# Create symlinks for all config files
./install.sh link

# Set up shell tools (Zap, fzf, bat)
./install.sh shell

# Install Homebrew packages from Brewfile
./install.sh brew

# Configure macOS system preferences
./install.sh macos

# Run all setup steps (recommended)
./install.sh all
```

## Post-Installation Setup

### Accessibility Permissions

After running `./install.sh all`, launch and grant accessibility permissions when prompted:

1. Karabiner-Elements
2. AeroSpace
3. Hammerspoon

All applications are configured to start automatically on subsequent logins.

### Font Installation

MonoLisa Nerd Font is used for terminal and text editors. To install:

1. Download the font files (.otf) from your Dropbox
2. Open Font Book (macOS Font Manager)
3. Drag and drop the .otf files into Font Book, or use File > Add Fonts
4. The font will be available system-wide once installed

### Raycast Configuration

Raycast is installed but requires manual setup:

1. Launch Raycast and set the hotkey to Cmd+Space
2. Disable Spotlight: System Settings > Keyboard > Keyboard Shortcuts > Spotlight > uncheck "Show Spotlight search"
3. (Optional) Enable Settings Sync in Raycast preferences for personal machines to sync extensions and configurations

## Git Configuration

- Shared settings: `~/.config/git/config` (symlinked from dotfiles)
- Machine-specific settings: `~/.gitconfig-local` (not in version control)

Edit `~/.gitconfig-local` to add machine-specific settings like email, name, or editor preferences.

### Convenience Commands

```bash
# Edit local machine-specific settings
git config-local user.email "your-email@example.com"

# Edit shared settings (in version control)
git config-shared alias.st "status"
```

## Zsh Configuration

- Shared settings: `~/.zshrc` (symlinked from dotfiles)
- Machine-specific settings: `~/.zshrc-local` (not in version control)

Edit `~/.zshrc-local` to add machine-specific settings like PATH modifications or local aliases.

## Directory Configuration

Add additional configuration files from a custom directory:

```bash
./install.sh link-dir /path/to/config/directory
```

This creates a "dotfiles overlay" by symlinking all files from the specified directory to your home directory. Use this when you want to add environment-specific or additional configuration files that aren't part of your main dotfiles repository.
