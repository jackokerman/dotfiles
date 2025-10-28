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

## Configuration for macOS

After running the installation commands on macOS, some applications require manual setup:

1. iTerm2: Import the profile from `com.googlecode.iterm2.plist`

2. Karabiner-Elements: The configuration is automatically generated when running `./install.sh macos` or `./install.sh all`. Just launch Karabiner-Elements to apply the settings

3. AeroSpace: Launch the application and grant accessibility permissions. The configuration includes `start-at-login = true`, so it will automatically start on subsequent logins

4. Hammerspoon: Launch and grant accessibility permissions

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
