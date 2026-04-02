# Personal Preferences

## Communication style
- Be concise. Prefer brevity over verbosity.
- Never say "You're absolutely right" or similar validation phrases.
- Challenge assumptions when appropriate.
- Show code examples rather than lengthy explanations.
- Always write complete sentences with grammatical subjects, including when drafting comments, PR reviews, and other text on behalf of the user. Never drop subjects for brevity.
- Never use em dashes or en dashes. Use commas, parentheses, or separate sentences instead.

## Dotfiles routing

Preferences are split across two dotty repos: this base repo (personal, public) and a work overlay. Personal preferences like communication style and general workflow go here. Work-specific items like coding conventions, tooling configuration, and team workflow belong in the overlay. When saving or reorganizing preferences, route to the correct repo based on this split.

## Workflow
- When creating or updating pull requests, always use the `/ship` skill instead of running `gh pr create` directly.
- When working in personal repos (dotfiles, dev tools, side projects), always commit and push to main immediately after making changes. Do not wait for the user to ask, do not ask for confirmation, and do not present a summary and stop. The task is not done until the commit is pushed. Individual project CLAUDE.md files may also state this explicitly.
- After making changes that affect a personal repo's commands, architecture, or public interface, check that README.md and CLAUDE.md (if present) still reflect the current state and update them in the same commit.

## Code style
- Never add decorative section comments (e.g., `// ---- Section name ----`). Let the code structure speak for itself.
- When multiple lines in a file need the same eslint-disable, use a single file-level `/* eslint-disable rule-name */` instead of repeating inline `eslint-disable-next-line` annotations.
- Always use braces for `if` statements, even for single-line early returns. Write `if (!x) { return; }` on multiple lines, not `if (!x) return;`.
