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

**Before choosing a placement**, understand the full configuration landscape. Not all preferences belong in Claude configuration — some belong in the dotfiles infrastructure itself (setup scripts, hook scripts, environment config). Read READMEs and setup/hook scripts in the target repo to understand what's already automated. If the preference relates to environment setup (MCP servers, CLI tools, shell plugins), it likely belongs in the dotfiles' own setup automation rather than a Claude skill or rule.

Then scan existing skills, rules, and CLAUDE.md files in the target repo for content that overlaps with the new preference. Use Glob and Read to check `skills/*/SKILL.md`, `rules/*.md`, `CLAUDE.md`, and any setup scripts. If an existing file already covers the topic (e.g., a `typescript-style` skill already has type conventions, or a setup script already manages MCP servers), update that file rather than creating a new entry elsewhere.

Also evaluate whether existing preferences are in the right place. If the scan reveals content that would be better located elsewhere (e.g., a coding convention in `CLAUDE.md` that belongs in a contextual skill, or scattered related preferences that should be consolidated), propose the reorganization alongside the new preference. Don't reinforce a bad structure by appending to it.

**When a preference already exists but wasn't followed:** If a rule or preference already exists in the configuration but Claude failed to follow it, do not dismiss the request with "this rule already exists." A violation means the current control surface isn't strong enough. Investigate why and propose escalating to a stronger mechanism:

- Advisory rules (`CLAUDE.md`, `rules/`) → enforced hooks (`PreToolUse`, `PostToolUse`)
- Broad rules → more specific, contextual rules (path-scoped, tool-scoped)
- Prose instructions → `settings.json` enforcement or hooks

The goal is continuous improvement. If a preference is being violated, the configuration needs to change.

Pick the configuration surface that best fits the preference. An important distinction: `CLAUDE.md`, rules, and skills are **advisory context** that Claude reads but may not follow strictly. `settings.json` permissions and hooks are **enforced** at runtime. If a preference keeps getting ignored in prose form, consider whether it can be expressed as a permission or hook instead.

**`settings.json`** for tool permissions, model configuration, or anything that must be enforced rather than suggested. Examples: "always allow web search", "use sonnet for quick tasks", "turn on extended thinking". These are key-value settings, not prose.

**`CLAUDE.md`** for small additions that fit an existing section. Read the current `CLAUDE.md` first. If there's already a relevant section (e.g., "Communication style"), append there. Keep in mind that `CLAUDE.md` and unconditional rules are loaded into context every session, so they should stay concise. If the file is growing long, preferences start competing for attention.

**`rules/`** for modular, topic-scoped preferences. Before deciding between `CLAUDE.md` and a new rule file, **scan existing `rules/` files** in the target repo. If an existing rule file covers the same topic (e.g., a workflow preference fits `git-workflow.md`), append to that file rather than `CLAUDE.md` or creating a new one. Rules without frontmatter are always loaded (like `CLAUDE.md`). Rules with `paths` frontmatter are conditionally loaded only when Claude reads files matching those patterns, which is ideal for language-specific or directory-specific conventions:

```yaml
---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---
# TypeScript conventions
Use explicit return types on exported functions.
```

Only create a new rule file when no existing file is a good fit and the preference doesn't belong in `CLAUDE.md`.

**`skills/`** for two cases:
- `user-invocable: false` for language/framework style guides or convention sets that should load contextually (e.g., when editing `.ts` files). Note: skills without `user-invocable: false` have their descriptions loaded every session so Claude knows when to auto-invoke them; the full content loads only on invocation.
- Full skills (user-invocable or auto-invocable) for distinct workflows

**Project-level `.claude/`** when the preference is specific to a single project rather than global. Place in the project's `.claude/CLAUDE.md`, `.claude/rules/`, or `.claude/settings.json` as appropriate.

When deciding, be pragmatic. A one-line preference belongs in `CLAUDE.md`, not a new rule file. A set of five related conventions might warrant a rule file or a path-scoped rule. A complex workflow with multiple steps is a skill. Don't create new files when appending to an existing one works.

### 5. Compose the directive

When writing the preference content:

- Frame positively: "use early returns" rather than "don't nest deeply"
- Include brief motivation when it's not obvious (e.g., "declarations are hoisted, so main components can go at the top of the file")
- Keep individual directives to one or two sentences
- Be mindful of file size for always-loaded files (`CLAUDE.md`, rules). If a file is getting long, suggest extracting to a skill instead
- For behavioral preferences (things Claude should do or stop doing), be explicit about the desired behavior change, not just the workflow. "Commit and push without asking for confirmation first" is a clear behavioral directive; "commit directly to main without PR review" describes the workflow but doesn't tell Claude to skip its default confirmation step. The difference matters because Claude's default cautious behaviors (asking before destructive actions, pausing before commits) won't change unless explicitly overridden.

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
