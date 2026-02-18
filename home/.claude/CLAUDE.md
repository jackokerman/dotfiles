# Personal Preferences

## Communication style
- Be concise. Prefer brevity over verbosity.
- Never say "You're absolutely right" or similar validation phrases.
- Challenge assumptions when appropriate.
- Show code examples rather than lengthy explanations.

## Dotfiles architecture

These dotfiles are managed by [dotty](https://github.com/jackokerman/dotty), a lightweight dotfile manager that supports chaining multiple repos together with overlay semantics.

### How dotty works

Dotty symlinks everything under a repo's `home/` directory into `$HOME`. Directories are merged intelligently: if both a base repo and an overlay repo contribute files to the same directory (e.g., `.config/git/`), dotty "explodes" the symlink into a real directory with individual file symlinks from each repo.

Key commands:

- `dotty install <path-or-url>` resolves the dependency chain, clones any missing repos, creates symlinks, and runs `dotty-run.sh` hooks.
- `dotty update [name]` pulls all repos in the chain, re-creates symlinks, and re-runs hooks.
- `dotty link [name]` re-creates symlinks only (skips pulls and hooks).
- `dotty status` shows registered repos, chain order, and detected environment.
- `dotty guard [path]` installs a pre-commit hook that blocks commits matching sensitive patterns.

### Chain and overlay system

The `dotty.conf` at the root of each repo defines its identity and dependencies:

```bash
DOTTY_NAME="dotfiles"
DOTTY_EXTENDS=()
```

This is the base repo with no dependencies. Overlay repos reference their parent via `DOTTY_EXTENDS`, forming a chain. Dotty processes the chain base-first so overlays can add or override files from earlier repos.

### Environment detection

Repos can define `DOTTY_ENVIRONMENTS` and `DOTTY_ENV_DETECT` in their `dotty.conf`. When environments are configured, dotty evaluates the detection expression and symlinks files from the matching environment directory (e.g., `laptop/` or `remote/`) after the base `home/` files.

### dotty-run.sh hooks

Each repo can include a `dotty-run.sh` script that runs after symlinks are created during `install` or `update`. The hook receives environment variables like `DOTTY_REPO_DIR`, `DOTTY_ENV`, `DOTTY_COMMAND`, and `DOTTY_LIB` (a utility library with helpers for logging, symlinks, and JSON merging).

### Guard system

`dotty guard` installs a git pre-commit hook that scans staged changes against patterns defined in `DOTTY_GUARD_PATTERNS`. This prevents accidentally committing sensitive content (internal URLs, company-specific identifiers) to the wrong repo.

Guard patterns are set as a newline-separated list of regexes in your shell environment, and the hook combines them with `|` for matching against `git diff --cached`.

### The `.local` suffix convention

Files ending in `.local` (like `.zshrc.local`, `.gitconfig.local`) are provided by overlay repos rather than the base. The base repo's files source the `.local` variants when they exist, so overlays can inject environment-specific configuration without modifying base files.

### Repo structure

```
dotfiles/
├── dotty.conf              # Repo identity and chain config
├── dotty-run.sh            # Post-symlink hook
├── install.sh              # Bootstrap script
├── Brewfile                # Homebrew packages
├── scripts/                # Setup helpers (macOS, fonts, etc.)
└── home/                   # Symlinked into $HOME
    ├── .zshenv
    ├── .claude/
    │   ├── CLAUDE.md       # This file
    │   └── rules/          # Claude Code rules
    ├── .config/
    │   ├── aerospace/      # Window manager
    │   ├── bat/            # Syntax highlighter
    │   ├── ghostty/        # Terminal
    │   ├── git/            # Git config
    │   ├── hammerspoon/    # Desktop automation
    │   └── zsh/            # Zsh config
    └── .raycast-scripts/   # Raycast commands
```

### Practical notes

- Test changes with `dotty update` before considering them done.
- Never commit secrets or credentials to this repo (it's public).
- The `home/` → `$HOME` mapping is the core mental model. If you want a file at `~/.config/foo/bar`, put it at `home/.config/foo/bar`.
- Overlay repos can add their own `home/.claude/rules/` and `home/.claude/commands/` files, which get merged into the same `~/.claude/` directory.
