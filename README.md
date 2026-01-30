# Dotfiles

My personal dotfiles. Includes cross-platform shell configurations and macOS-specific system settings.

## Installation

1. Clone this repository to your home directory:

```bash
cd ~
git clone https://github.com/jackokerman/dotfiles.git
cd dotfiles
```

2. Download MonoLisa font (installed automatically by the setup script):
   - Visit the [MonoLisa orders page](https://www.monolisa.dev/orders) and log in with your email and order number (check your purchase confirmation email)
   - Download the **Complete** version (variable fonts) ZIP to `~/Downloads/`
   - The install script will extract and install it automatically
   - **Note**: [Symbols Nerd Font](https://github.com/ryanoasis/nerd-fonts) (for terminal icons) is downloaded automatically during setup.

3. Run the install script:

```bash
# Run all setup steps (recommended)
./install.sh all

# Or run individual steps:
./install.sh link   # Create symlinks for config files
./install.sh shell  # Set up shell tools (fzf, bat)
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
- Machine-specific settings: `~/.gitconfig.local` (not in version control)

Edit `~/.gitconfig.local` to add machine-specific settings like email, name, or editor preferences.

### Convenience Commands

```bash
# Edit local machine-specific settings
git config-local user.email "your-email@example.com"

# Edit shared settings (in version control)
git config-shared alias.st "status"
```

## Zsh Configuration

- Shared settings: `~/.zshrc` and `~/.zshenv` (symlinked from dotfiles)
- Machine-specific settings: `~/.zshrc.local` and `~/.zshenv.local` (not in version control)

Use `.zshenv.local` for environment variables (PATH, exports) and `.zshrc.local` for interactive shell settings (aliases, functions).

## Directory Configuration

Add additional configuration files from a custom directory:

```bash
./install.sh link-dir /path/to/config/directory
```

This creates a "dotfiles overlay" by symlinking files to your home directory. Existing files are never overwritten (skipped with a warning), and directories are merged recursively.

Example overlay structure:

```
work-dotfiles/
├── .gitconfig.local                  # Work email and signing key
├── .zshenv.local                     # Work-specific PATH and env vars
├── .zshrc.local                      # Work-specific aliases and functions
└── .config/
    └── hammerspoon/
        └── init.local.lua            # Work-specific key bindings
```

Files are symlinked to `$HOME`, so `.gitconfig.local` becomes `~/.gitconfig.local`.
