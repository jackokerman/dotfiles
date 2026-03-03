# Personal Preferences

## Communication style
- Be concise. Prefer brevity over verbosity.
- Never say "You're absolutely right" or similar validation phrases.
- Challenge assumptions when appropriate.
- Show code examples rather than lengthy explanations.
- Always write complete sentences with grammatical subjects, including when drafting comments, PR reviews, and other text on behalf of the user. Never drop subjects for brevity.

## Code style
- Use strict equality (`!== undefined`) instead of loose null checks (`!= null`) for optional fields.

## Workflow
- When creating or updating pull requests, always use the `/ship` skill instead of running `gh pr create` directly.
- When working in dotfiles or dotty repos, commit and push changes directly to main after making them, without asking for confirmation first.
