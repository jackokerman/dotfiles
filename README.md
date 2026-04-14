# Dotfiles

My personal dotfiles. Managed by [dotty](https://github.com/jackokerman/dotty), a bash dotfiles manager with overlay semantics. Includes cross-platform shell configurations and macOS-specific system settings.

## Installation

1. Clone this repository and run the install script:

```bash
git clone https://github.com/jackokerman/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

This installs [dotty](https://github.com/jackokerman/dotty) if needed, then creates symlinks and runs hooks (shell tools, Homebrew packages, macOS preferences, etc.).

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
- Git diffs use `delta` as the shared pager for `git diff`, `git show`, and patch-style `git log` output.
- `delta` theme selection is configured in git, not inherited from bat. This repo pins `delta.syntax-theme=fly16` to match the existing bat theme.

Edit `~/.gitconfig.local` to add machine-specific settings like email, name, or editor preferences.

```bash
# Edit local machine-specific settings
git config-local user.email "your-email@example.com"

# Edit shared settings (in version control)
git config-shared alias.st "status"
```

After changing tracked git config, run `dotty update` so the live `~/.config/git/config` is regenerated before testing.

## Zsh configuration

- Shared settings: `~/.config/zsh/.zshrc` (via `ZDOTDIR`, set in `~/.zshenv`) and `~/.zshenv` (symlinked from dotfiles)
- Machine-specific settings: `~/.zshrc.local` and `~/.zshenv.local` (not in version control)

Use `.zshenv.local` for environment variables (PATH, exports) and `.zshrc.local` for interactive shell settings (aliases, functions).

### Plugin management

Plugins are managed by zetch, a minimal plugin manager defined in `.config/zsh/.zetch.zsh`. It clones plugins from GitHub on first run (in parallel for fast setup) and sources them in the right order.

To add a plugin, add the `owner/repo` to the `plugins` array in `.zshrc` and add a `zetch owner/repo` call in the appropriate position. To remove one, delete both lines.

To update all plugins:

```zsh
zetch-update
```

## tmux and Ghostty

- `tmux` is configured with `terminal-features 'xterm*:hyperlinks'`, so OSC 8 hyperlinks survive through `tmux` into Ghostty.
- In Ghostty, use `Cmd+Click` to open links. Plain click still belongs to `tmux` mouse handling for pane selection and resizing.
- Reload a running `tmux` server after config changes with `tmux source-file ~/.config/tmux/tmux.conf` or the existing `prefix + r` binding.
- Run `tmux-link-test` inside `tmux` to print both an OSC 8 hyperlink and a plain URL for quick verification.
- If `tmux-link-test` works but an agent-produced link does not, the agent printed plain text rather than an OSC 8 hyperlink.

## tmux agent status

- The tmux status renderer reads explicit session state files from `/tmp/tmux-agent-$(id -u)`.
- Agents integrate by writing `agent<TAB>state` through `~/.config/tmux/agent-status-hook.sh <working|waiting|done> <agent>`.
- Known local `codex` and `claude` sessions still use a small pane-tail fallback to refine `working` and `waiting`, but explicit state files remain the source of truth and finished shell-only sessions are hidden once no live agent process remains.
- Overlay repos can mirror remote state into `/tmp/tmux-agent-$(id -u)/remote/` and canonicalize mirrored sessions to the devbox-named local tmux session so wrapper aliases do not surface separately.

## Codex configuration

- Tracked Codex source inputs live in `home/.codex/`.
- The dotty hook keeps `~/.codex` as a real directory so Codex can continue writing local state there.
- `~/.codex/AGENTS.md`, `~/.codex/config.toml`, and `~/.codex/hooks.json` are generated from tracked fragments when you run `dotty update`.
- Tracked native Codex skills under `home/.codex/skills/` are copied into `~/.codex/skills/` when you run `dotty update`.
- Tracked native Codex agents under `home/.codex/agents/` are synced into `~/.codex/agents/`. Agent TOMLs can reference tracked skills with `skill://<name>`, and the sync rewrites those entries to the live absolute `~/.codex/skills/<name>/SKILL.md` path.
- Do not edit generated runtime outputs under `~/.codex`; update the tracked sources in this repo and rerun `dotty update`.
- Tracked `config.toml` fragments are deep-merged over the live local file: tables merge recursively and arrays are replaced by later sources.
- Tracked `hooks.json` fragments are composed by event name in source order. If multiple repos define hooks for the same event, earlier hooks run first and later hooks append.
- Tracked Codex theme assets live in `home/.codex/themes/` and are symlinked into `~/.codex/themes/` when you run `dotty update`.
- `tui.theme` selects the matching `.tmTheme` file by name, so `theme = "nightfly"` expects `~/.codex/themes/nightfly.tmTheme`.
- Codex hooks are enabled in the managed config and the shared `hooks.json` writes tmux session state for Codex sessions.
- The managed Codex defaults run with `approval_policy = "never"` and `sandbox_mode = "danger-full-access"`, so local Codex sessions do not stop for routine approval prompts.
- Codex commit attribution is disabled in the managed config so agent-made commits do not add Codex trailers by default.
- Codex fragments are validated during sync. Invalid JSON/TOML or malformed hook entries cause `dotty update` to fail before the live files are replaced.

### Codex pre-commit validation

Install the tracked repo-local pre-commit hook once per clone:

```bash
./scripts/install-git-hooks.sh
```

The hook runs Codex fragment validation before commit. It preserves any existing repo-local pre-commit hook by moving it to `.git/hooks/pre-commit.local` and chaining to it first.

Temporary bypass:

```bash
SKIP_CODEX_SYNC_VALIDATE=1 git commit -m "..."
```

## Layering with other repos

This repo is designed as a base layer. Work or machine-specific dotfiles can extend it using dotty's overlay system. See the [dotty README](https://github.com/jackokerman/dotty) for details on multi-repo chains and the extend pattern.
