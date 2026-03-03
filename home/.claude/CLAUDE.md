# Personal Preferences

## Communication style
- Be concise. Prefer brevity over verbosity.
- Never say "You're absolutely right" or similar validation phrases.
- Challenge assumptions when appropriate.
- Show code examples rather than lengthy explanations.
- Always write complete sentences with grammatical subjects, including when drafting comments, PR reviews, and other text on behalf of the user. Never drop subjects for brevity.

## Dotfiles routing

Preferences are split across two dotty repos: this base repo (personal, public) and a work overlay. Personal preferences like communication style and general workflow go here. Work-specific items like coding conventions, tooling configuration, and team workflow belong in the overlay. When saving or reorganizing preferences, route to the correct repo based on this split.

## Workflow
- When creating or updating pull requests, always use the `/ship` skill instead of running `gh pr create` directly.
- When working in dotfiles or dotty repos, commit and push changes directly to main after making them, without asking for confirmation first.
