# Dotfiles

My personal dotfiles. Includes cross-platform shell configurations and macOS-specific system settings.

## Installation

1. Clone this repository to your home directory:

```bash
cd ~
git clone https://github.com/jackokerman/dotfiles.git
cd dotfiles
```

2. (Optional) Download MonoLisa font:
   - Visit the [MonoLisa orders page](https://www.monolisa.dev/orders) and log in with your email and order number
   - Download and place the ZIP file in `fonts/monolisa/source/`
   - The font will be automatically patched and installed during setup

3. Run the install script:

```bash
# Run all setup steps (recommended)
./install.sh all

# Or run individual steps:
./install.sh link   # Create symlinks for config files
./install.sh shell  # Set up shell tools (Zap, fzf, bat)
./install.sh brew   # Install Homebrew packages
./install.sh macos  # Configure macOS system preferences
```

## Post-Installation Setup

### Accessibility Permissions

After running `./install.sh all`, launch and grant accessibility permissions when prompted:

1. Karabiner-Elements
2. AeroSpace
3. Hammerspoon

All applications are configured to start automatically on subsequent logins.

### iTerm2 Configuration

To import iTerm2 profiles:

1. Open iTerm2 Settings → Profiles
2. Click "Other Actions..." (bottom left) → Import JSON Profiles
3. Select `config/iterm2/Profiles.json` from your dotfiles directory
4. Set the imported profile as your default

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
