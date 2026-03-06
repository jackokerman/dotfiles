# Conventional commits

Use Conventional Commits for commit messages in personal repos (dotfiles, dotfiles overlays, and
personal dev tools). Do not apply this to work repos, which follow their own conventions.

## Format

```
<type>: <description>

[optional body]

[optional footer(s)]
```

## Types

- `feat`: new functionality
- `fix`: bug fix
- `refactor`: restructuring without behavior change
- `chore`: maintenance, dependencies, config
- `docs`: documentation only
- `test`: adding or updating tests
- `style`: formatting, whitespace (not CSS)

## Rules

- The description (first line) should be lowercase after the type prefix and not end with a period.
- Use a blank line between the description and body.
- The body is optional. Use it when the "why" isn't obvious from the description alone.
- Don't use scopes (e.g., `feat(context):`) unless a project grows large enough to need them.
- Use `!` after the type for breaking changes: `feat!: change context source return type`.
- Footers use git trailer syntax: `Refs: DEVVY-42`, `BREAKING CHANGE: description`.

## Examples

```
feat: add Slack thread context source
```

```
fix: handle missing Jira assignee field

The Jira API returns `null` for unassigned tickets, but we were
destructuring the assignee object unconditionally.
```

```
refactor: extract subprocess helpers into `exec` module
```

```
chore: update deno dependencies
```
