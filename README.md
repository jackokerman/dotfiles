# Dotfiles

My personal dotfiles. Managed by [dotty](https://github.com/jackokerman/dotty), a bash dotfiles manager with overlay semantics. Includes cross-platform shell configurations and macOS-specific system settings.

## Installation

1. Clone this repository and run the install script:

```bash
git clone https://github.com/jackokerman/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

This installs [dotty](https://github.com/jackokerman/dotty) if needed, then creates symlinks and runs setup hooks (shell tools, Homebrew packages, macOS preferences, etc.).

2. Download MonoLisa font (installed automatically by the setup script):
   - Visit the [MonoLisa orders page](https://www.monolisa.dev/orders) and log in with your email and order number (check your purchase confirmation email)
   - Download the **Complete** version (variable fonts) ZIP to `~/Downloads/`
   - The install script will extract and install it automatically
   - **Note**: [Symbols Nerd Font](https://github.com/ryanoasis/nerd-fonts) (for terminal icons) is downloaded automatically during setup.

## Updating

```bash
dotty update
```

This pulls the latest changes and re-runs symlinks and setup hooks.

## Post-installation setup

### Accessibility permissions

After installation, launch and grant accessibility permissions when prompted:

1. Karabiner-Elements
2. AeroSpace
3. Hammerspoon

All applications are configured to start automatically on subsequent logins.

### Raycast configuration

Raycast is installed but requires manual setup:

1. Launch Raycast and set the hotkey to Cmd+Space
2. Disable Spotlight: System Settings > Keyboard > Keyboard Shortcuts > Spotlight > uncheck "Show Spotlight search"
3. (Optional) Enable Settings Sync in Raycast preferences for personal machines to sync extensions and configurations

Custom script commands are included in `home/.raycast-scripts/`. After installation, add the script directory to Raycast:
1. Raycast Preferences > Extensions > Script Commands
2. Add Directory: `~/.raycast-scripts`

## Git configuration

- Shared settings: `~/.config/git/config` (symlinked from dotfiles)
- Machine-specific settings: `~/.gitconfig.local` (not in version control)

Edit `~/.gitconfig.local` to add machine-specific settings like email, name, or editor preferences.

```bash
# Edit local machine-specific settings
git config-local user.email "your-email@example.com"

# Edit shared settings (in version control)
git config-shared alias.st "status"
```

## Zsh configuration

- Shared settings: `~/.config/zsh/.zshrc` (via `ZDOTDIR`, set in `~/.zshenv`) and `~/.zshenv` (symlinked from dotfiles)
- Machine-specific settings: `~/.zshrc.local` and `~/.zshenv.local` (not in version control)

Use `.zshenv.local` for environment variables (PATH, exports) and `.zshrc.local` for interactive shell settings (aliases, functions).

## Layering with other repos

This repo is designed as a base layer. Work or machine-specific dotfiles can extend it using dotty's overlay system. See the [dotty README](https://github.com/jackokerman/dotty) for details on multi-repo chains and the extend pattern.
