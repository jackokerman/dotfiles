---
name: bash-style
description: Use when creating or editing Bash, shell, or zsh scripts, including `.sh`, `.bash`, `.zsh`, shell hooks, and CLI helper scripts.
---

# Bash Style

Use this skill for shell scripts and shell-based helper tools. Prefer the local project style when it is already clear, and apply these defaults when the surrounding code does not establish something stronger.

## Shell Choice

- Prefer Bash for scripts. Use `#!/usr/bin/env bash` for executable scripts so macOS can pick up Homebrew Bash when available.
- Treat zsh as the interactive shell unless a script is explicitly zsh-specific.
- Keep POSIX `sh` only when portability to minimal shells is a real requirement.

## Script Shape

- Start non-trivial Bash scripts with `set -euo pipefail`.
- Keep scripts flat and procedural. Add helpers only when they remove real repetition or clarify a distinct operation.
- Use early `return`, `continue`, or `exit` paths to avoid deeply nested conditionals.
- Keep the happy path easy to scan. Three similar direct commands are often clearer than a premature abstraction.

## Comments

- Comment on why, not what. Do not restate the command in prose.
- Keep file headers to one or two lines that state the script's purpose. Skip author, date, and license boilerplate unless the repo already uses it.
- Avoid decorated section headers such as `# ====`, `# ----`, or `# --- name ---`. Use a plain comment with surrounding blank lines when a section marker helps.

## Functions

- Use descriptive names. A name like `_resolve_chain` is better than `_resolve` plus a comment explaining what it resolves.
- Prefix private helpers with `_`, such as `_link_item`.
- Prefix command implementations with `cmd_`, such as `cmd_install` or `cmd_status`, when a script dispatches subcommands.
- Use `local` by default inside functions.
- Define helpers near the code that uses them when that improves readability. Do not force a large helper prelude at the top of every file.

## Variables And Expansions

- Use `SCREAMING_SNAKE_CASE` for constants and script-level globals.
- Mark constants with `readonly` when they should not change.
- Quote variable expansions as `"${var}"` unless a shell pattern or word-splitting behavior is intentionally required.
- Prefer `"${var:-default}"` for simple defaults.
- Use `$(...)` for command substitution, not backticks.

## Conditionals And Output

- Prefer `[[ ... ]]` over `[ ... ]` in Bash scripts.
- Prefer `printf` over `echo` for formatted output, escape-sensitive text, and anything that may start with `-`.
- Validate required arguments early and fail with a clear message.
- Use a small `die` helper for repeated fatal errors instead of scattering inline `printf ... >&2` plus `exit 1`.

## Portability

- Handle GNU/BSD differences for tools such as `sed`, `date`, `stat`, and `readlink` when the script is expected to run on both macOS and Linux.
- Verify command availability before depending on optional tools in setup, install, or bootstrap scripts.
- Avoid adding portability branches for environments the script does not actually support.
