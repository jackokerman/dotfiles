---
name: claudify
description: >-
  Persist a preference, convention, or pattern to Claude Code configuration.
  Use when the user corrects Claude's approach, expresses a preference,
  or asks Claude to remember something ("always do X", "never do Y",
  "I prefer X", "why did you do it that way", "can we do X instead",
  "from now on", "remember this").
---

# Claudify

Save a preference, convention, or pattern to Claude Code configuration so it persists across sessions.

## Arguments

The user can pass a description directly: `/claudify "prefer simple bash headers"`. When arguments are provided, use them as the preference description instead of asking.

## Confirming intent

Always confirm what you're about to save before making changes, regardless of how the skill was invoked. Don't infer preferences from conversation context. Ask the user what they want to persist, or if they passed arguments, confirm your interpretation.

When auto-invoked (the user didn't type `/claudify`), propose saving the preference first:

> That sounds like a preference worth saving for future sessions. Want me to persist it?

Only proceed if the user confirms.

## Workflow

### 1. Understand the preference

The user will describe something they want to remember. If they passed arguments, use those. Otherwise ask what they'd like to save.

Examples of persistent preferences:
- A coding convention ("always use early returns")
- A tool preference ("use pnpm instead of npm")
- A workflow pattern ("run tests before committing")
- A writing style ("don't use em dashes")
- A tool permission ("always allow web search")

**Is it actually a persistent preference?** Not every correction is one. "Use a different variable name here" or "fix the typo on line 12" are local edits, not preferences. Look for language that implies generality: "always", "never", "I prefer", "from now on", or corrections to Claude's default behavior that would apply across sessions.

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

Pick the configuration surface that best fits the preference:

**`settings.json`** for tool permissions or model configuration. Examples: "always allow web search", "use sonnet for quick tasks", "turn on extended thinking". These are key-value settings, not prose.

**`CLAUDE.md`** for small additions that fit an existing section. Read the current `CLAUDE.md` first. If there's already a relevant section (e.g., "Communication style"), append there. This is the most common target for simple preferences.

**`rules/`** for small, always-applicable preferences that deserve their own file. Good for things like writing style, commit conventions, or formatting rules that don't fit an existing `CLAUDE.md` section and would clutter it.

**`skills/`** for two cases:
- `user-invocable: false` for language/framework style guides or convention sets that should load contextually (e.g., when editing `.ts` files)
- Full skills (user-invocable or auto-invocable) for distinct workflows

**Project-level `.claude/`** when the preference is specific to a single project rather than global. Place in the project's `.claude/CLAUDE.md`, `.claude/rules/`, or `.claude/settings.json` as appropriate.

When deciding, be pragmatic. A one-line preference belongs in `CLAUDE.md`, not a new rule file. A set of five related conventions might warrant a rule file. A complex workflow with multiple steps is a skill. Don't create new files when appending to an existing one works.

### 5. Compose the directive

When writing the preference content:

- Frame positively: "use early returns" rather than "don't nest deeply"
- Include brief motivation when it's not obvious (e.g., "declarations are hoisted, so main components can go at the top of the file")
- Keep individual directives to one or two sentences
- Be mindful of file size for always-loaded files (`CLAUDE.md`, rules). If a file is getting long, suggest extracting to a skill instead

### 6. Show proposed change

Display the exact change you plan to make:
- Which file (full path)
- Whether it's a new file or edit to an existing one
- The content being added or modified

Ask for confirmation before proceeding.

### 7. Apply and commit

**IMPORTANT: Every change to a dotfiles repo MUST be committed and pushed before the task is considered done. Never leave changes uncommitted or unpushed.**

1. Make the change
2. Stage and commit in the target dotfiles repo (not the current working directory) with a descriptive message, e.g.: "Add preference for early returns in TypeScript"
3. Push to the repo's remote main branch
