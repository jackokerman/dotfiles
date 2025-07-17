# Dotfiles

My personal dotfiles. Includes cross-platform shell configurations and macOS-specific system settings.

## Installation

1. Clone this repository:

```bash
git clone https://github.com/jackokerman/dotfiles.git
cd dotfiles
```

2. Run the install script with desired options:

```bash
# To create symlinks only (zsh config, bat themes, etc.)
./install.sh link

# To set up shell tools (Zap, fzf, bat)
./install.sh shell

# To do both (recommended)
./install.sh all
```

## Additional setup commands

### macOS system preferences
Configure system preferences and defaults:

```bash
./macos
```

### Install homebrew applications
Install all applications and packages defined in Brewfile:

```bash
brew bundle
```

### Karabiner-elements configuration
Generate and install Karabiner-Elements configuration:

```bash
deno run --allow-env --allow-read --allow-write karabiner-config.ts
```

## Manual configuration steps

After running the installation commands, some applications require manual setup:

1. **iTerm2**: Import the profile from `com.googlecode.iterm2.plist`
2. **Karabiner-Elements**: Use the generated configuration
3. **yabai & skhd**: Start the services and grant accessibility permissions
4. **Hammerspoon**: Grant accessibility permissions and load the configuration

## Quick setup for new machine

For a complete setup on a new machine, run these commands in order:

```bash
git clone https://github.com/jackokerman/dotfiles.git
cd dotfiles
./install.sh all
./macos
brew bundle
deno run --allow-env --allow-read --allow-write karabiner-config.ts
```
