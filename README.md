# Dotfiles

## Dotfile Setup
1. Install Xcode command line tools:
```shell
xcode-select --install
```

2. Install homebrew:
```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. Install and initialize chezmoi:
```shell
sh -c "$(curl -fsLS chezmoi.io/get)" -- init --apply jackokerman
```

## Mac Setup
- Login with Apple ID and ensure iCloud Drive syncing is enabled (some apps use this for syncing data and settings)
- Map Caps Lock key to Control
- Setup Rectangle Pro window management
  - Open the app and update accessibility settings when prompted
  - In settings, check "Sync configuration over iCloud" to load saved settings
- Disable spotlight keyboard shortcut
- Download "New Machine" directory from Dropbox and install patched fonts
- Run `mackup restore` to restore settings for apps saced with [mackup](https://github.com/lra/mackup)
- Setup VS Code
  - Enable Setting Sync to pull down saved settings
