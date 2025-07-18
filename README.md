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

1. **iTerm2**: Import the profile from `com.googlecode.iterm2.plist`

2. **Karabiner-Elements**: Generate configuration with:
   ```bash
   deno run --allow-env --allow-read --allow-write karabiner-config.ts
   ```

3. **yabai & skhd**: Start the services and grant accessibility permissions:
   ```bash
   yabai --start-service
   skhd --start-service
   ```

4. **Hammerspoon**: Launch and grant accessibility permissions
