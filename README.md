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
- Map Caps Lock key to Control
- Setup Rectangle Pro window management
  - Open the app and update accessibility settings when prompted
  - In settings, check "Sync configuration over iCloud" to load saved settings
- Disable spotlight keyboard shortcut
- Setup Raycast
  - Set hotkey to `Command+Space`
  - Set hotkey for emoji search to `^+Option+Space` to replace defaul emoji keyboard
