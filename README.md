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

Configure iTerm2 to load preferences from your dotfiles:

1. Open iTerm2 → Settings → General → Preferences
2. Check "Load preferences from a custom folder or URL"
3. Set the folder path to your dotfiles directory (e.g., `~/dotfiles`)
4. When prompted to save current settings, click "Cancel"
5. Quit iTerm2 and relaunch to load preferences from your dotfiles
6. (Optional) Check "Save changes to folder when iTerm2 quits" to automatically save settings changes

### Raycast Configuration

Raycast is installed but requires manual setup:

1. Launch Raycast and set the hotkey to Cmd+Space
2. Disable Spotlight: System Settings > Keyboard > Keyboard Shortcuts > Spotlight > uncheck "Show Spotlight search"
3. (Optional) Enable Settings Sync in Raycast preferences for personal machines to sync extensions and configurations

#### Raycast Script Commands

Custom script commands are included in `config/raycast-scripts/`.

After running `./install.sh link`, add the script directory to Raycast:
1. Raycast Preferences → Extensions → Script Commands
2. Add Directory: `~/.config/raycast-scripts`

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
