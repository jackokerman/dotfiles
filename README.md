# Dotfiles
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
