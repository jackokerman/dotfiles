---
name: claudify
description: Add or update a Claude Code preference, convention, or pattern in the appropriate dotfiles repo
disable-model-invocation: true
---

# Claudify

Save a preference, convention, or pattern to Claude Code configuration so it persists across sessions.

## Workflow

### 1. Understand the preference

The user will describe something they want Claude to remember, like:
- A coding convention ("always use early returns")
- A tool preference ("use pnpm instead of npm")
- A workflow pattern ("run tests before committing")

If the description is vague, ask a clarifying question.

### 2. Discover dotfile repos

Run `dotty status` to get the chain order and repo paths. Example output:

```
==> dotty status
  Chain: base-dotfiles → work-dotfiles
  Env:   laptop

  ✓ base-dotfiles (/Users/you/base-dotfiles) [clean]
  ✓ work-dotfiles (/Users/you/work-dotfiles) [clean]
```

Parse the chain order (first repo is the base, subsequent repos are overlays) and the repo paths from the status lines.

If `dotty status` fails, fall back to reading `~/.dotty/registry` (format: `name=/path` per line). If that also fails, use `~/.claude/` directly and skip routing entirely.

### 3. Route to the correct repo

**Single repo or no dotty:** Skip routing. Place everything in the one available repo.

**Two repos:** Use `$DOTTY_GUARD_PATTERNS` (newline-separated regexes) to classify the preference content. If the preference text, file paths, or identifiers match any guard pattern, route to the overlay repo (later in the chain). Otherwise route to the base repo (first in the chain).

**Three or more repos:** Same guard-pattern check. If the content matches a guard pattern and there are multiple overlay repos, present the overlay options and ask which one.

If `$DOTTY_GUARD_PATTERNS` is unset, route everything to the base repo.

### 4. Determine placement

Decide whether to add to an existing file or create a new one:

**Add to existing rule or skill** when the preference fits naturally within an existing file's scope. Read the candidate file first to confirm it's a good fit.

**Create a new skill** when the preference represents a distinct workflow or domain that doesn't fit existing files. Use `user-invocable: false` for style/convention preferences, `disable-model-invocation: true` for explicit workflows.

**Create a new rule** only for small, always-applicable preferences (like writing style) that should load into every conversation.

### 5. Show proposed change

Display the exact change you plan to make:
- Which file (full path)
- Whether it's a new file or edit to an existing one
- The content being added or modified

Ask for confirmation before proceeding.

### 6. Apply and commit

1. Make the change
2. Commit with a message like: "Add preference for early returns in TypeScript"
3. Push to the repo's main branch
