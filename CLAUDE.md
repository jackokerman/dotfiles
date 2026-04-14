# dotfiles

Personal dotfiles managed by [dotty](https://github.com/jackokerman/dotty), a lightweight dotfile manager that supports chaining multiple repos together with overlay semantics. After making changes, commit and push directly to main without PR review.

## How dotty works

Dotty symlinks everything under a repo's `home/` directory into `$HOME`. Directories are merged intelligently: if both a base repo and an overlay repo contribute files to the same directory (e.g., `.config/git/`), dotty "explodes" the symlink into a real directory with individual file symlinks from each repo.

Key commands:

- `dotty install <path-or-url>` resolves the dependency chain, clones any missing repos, creates symlinks, and runs hooks.
- `dotty update [name]` pulls all repos in the chain, re-creates symlinks, and re-runs hooks.
- `dotty link [name]` re-creates symlinks only (skips pulls and hooks).
- `dotty status` shows registered repos, chain order, and detected environment.
- `dotty guard [path]` installs a pre-commit hook that blocks commits matching sensitive patterns.

## Chain and overlay system

The `.dotty/config` in each repo defines its identity and dependencies:

```bash
DOTTY_NAME="dotfiles"
DOTTY_EXTENDS=()
```

This is the base repo with no dependencies. Overlay repos reference their parent via `DOTTY_EXTENDS`, forming a chain. Dotty processes the chain base-first so overlays can add or override files from earlier repos.

## Environment detection

Repos can define `DOTTY_ENVIRONMENTS` and `DOTTY_ENV_DETECT` in their `.dotty/config`. When environments are configured, dotty evaluates the detection expression and symlinks files from the matching environment directory (e.g., `laptop/` or `remote/`) after the base `home/` files.

## Hooks

Each repo can include a `.dotty/run.sh` script that runs after symlinks are created during `install` or `update`. The hook receives environment variables like `DOTTY_REPO_DIR`, `DOTTY_ENV`, `DOTTY_COMMAND`, and `DOTTY_LIB` (a utility library with helpers for logging and symlinks).

## Guard system

`dotty guard` installs a git pre-commit hook that scans staged changes against patterns defined in `DOTTY_GUARD_PATTERNS`. This prevents accidentally committing sensitive content (internal URLs, company-specific identifiers) to the wrong repo.

Guard patterns are set as a newline-separated list of regexes in your shell environment, and the hook combines them with `|` for matching against `git diff --cached`.

## The `.local` suffix convention

Files ending in `.local` (like `.zshrc.local`, `.gitconfig.local`) are provided by overlay repos rather than the base. The base repo's files source the `.local` variants when they exist, so overlays can inject environment-specific configuration without modifying base files.

## Plugin management (zetch)

Zetch is a minimal zsh plugin manager defined in `home/.config/zsh/.zetch.zsh`. It exposes four subcommands through a single `zetch` function:

- `zetch install` clones missing plugins in parallel (backgrounds each `git clone` and `wait`s). This makes fresh installs on new machines fast. It's a no-op when everything is already installed.
- `zetch <owner/repo>` sources a single plugin by auto-detecting its init file. It caches the detection result as a symlink so subsequent shells skip the glob.
- `zetch compinit` prepends directories to `fpath` and runs `compinit` with a double-init guard.
- `zetch update` pulls all plugins by globbing `$ZPLUGINDIR/*/.git`.

The ordering in `.zshrc` matters. Powerlevel10k must load first (instant prompt). fpath directories and `compinit` must run before fzf-tab. fzf-tab must load before widget-wrapping plugins (autosuggestions, tab-title). `zsh-syntax-highlighting` must come before `zsh-history-substring-search` per upstream docs.

## Repo structure

```
dotfiles/
├── .dotty/
│   ├── config              # Repo identity and chain config
│   └── run.sh              # Post-symlink hook
├── AGENTS.md               # Codex repo-scoped instructions
├── install.sh              # Bootstrap script
├── Brewfile                # Homebrew packages
├── CLAUDE.md               # This file (repo-scoped instructions)
├── scripts/                # Setup helpers (macOS, fonts, etc.)
└── home/                   # Symlinked into $HOME
    ├── .zshenv
    ├── .codex/
    │   ├── AGENTS.md       # Codex home-level instruction fragment
    │   ├── agents/         # Tracked native Codex agents
    │   ├── config.toml     # Codex managed default fragment
    │   ├── hooks.json      # Codex managed hooks fragment
    │   ├── skills/         # Tracked native Codex skills
    │   └── themes/         # Tracked Codex themes
    ├── .claude/
    │   ├── CLAUDE.md       # Global user preferences (symlinked to ~/.claude/)
    │   ├── settings.json   # Claude Code settings
    │   ├── rules/          # Claude Code rules (always-on)
    │   └── skills/         # Claude Code skills (contextual)
    ├── .config/
    │   ├── aerospace/      # Window manager
    │   ├── bat/            # Syntax highlighter
    │   ├── ghostty/        # Terminal
    │   ├── git/            # Git config
    │   ├── hammerspoon/    # Desktop automation
    │   └── zsh/            # Zsh config (.zetch.zsh, .zshrc, .aliases, etc.)
    ├── .local/bin/          # User scripts on PATH
    └── .raycast-scripts/   # Raycast commands
```

## Practical notes

- Test changes with `dotty update` before considering them done.
- Never commit secrets or credentials to this repo (it's public).
- The `home/` → `$HOME` mapping is the core mental model. If you want a file at `~/.config/foo/bar`, put it at `home/.config/foo/bar`.
- Ghostty link opening through `tmux` relies on the tracked `home/.config/tmux/tmux.conf` line `set -ga terminal-features 'xterm*:hyperlinks'`. Use `Cmd+Click`, not plain click.
- `tmux-link-test` is the quick verification path inside `tmux`: it prints one OSC 8 hyperlink and one plain URL so link handling is easy to distinguish from application output.
- Shared git diffs are rendered through `delta`. Keep `home/.config/git/config` as the source of truth for pager behavior and `delta` theme selection.
- `delta` does not inherit `bat`'s config automatically. If bat theme changes, update `delta.syntax-theme` explicitly to keep git diffs visually aligned.
- Overlay repos can add their own `home/.claude/rules/`, `home/.claude/skills/`, and `home/.claude/commands/` files, which get merged into the same `~/.claude/` directory.
- Codex uses the same pattern: `home/.codex/AGENTS.md`, `home/.codex/config.toml`, and `home/.codex/hooks.json` are tracked source fragments, while tracked `home/.codex/skills/` and `home/.codex/agents/` are synced into the live `~/.codex/skills/` and `~/.codex/agents/` directories. Agent TOMLs can use `skill://<name>` for tracked skills, and the sync rewrites those references to live absolute `SKILL.md` paths. Do not edit generated `~/.codex` outputs directly. The managed Codex config also sets `approval_policy = "never"`, `sandbox_mode = "danger-full-access"`, `commit_attribution = ""`, and enables `features.codex_hooks = true`.
- Tracked Codex `config.toml` fragments are deep-merged over the live local file. Tables merge recursively and arrays are replaced by later sources.
- Tracked Codex `hooks.json` fragments compose by event name in source order. When multiple fragments define the same event, keep the earlier hooks and append later hooks after them.
- The Codex sync validates tracked fragments before writing the live files. Malformed JSON/TOML or invalid hook entries should make `dotty update` fail.
- Codex theme files under `home/.codex/themes/` are tracked assets, not merged config. Keep `nightfly.tmTheme` aligned with the upstream `fly16` syntax map and Nightfly palette, then validate visual changes in Codex and run `dotty update`.
- Repo-local Codex pre-commit validation is opt-in via `scripts/install-git-hooks.sh`. That installer chains any existing `.git/hooks/pre-commit` through `.git/hooks/pre-commit.local` before running the tracked `.githooks/pre-commit` validator.
