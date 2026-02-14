# Bash scripting style

## General principles

- Always start scripts with `set -euo pipefail`
- Keep scripts flat and procedural. Avoid unnecessary abstraction layers.
- Use early returns (`return`, `continue`) to reduce nesting
- Don't over-engineer. Three similar lines are better than a premature helper function.

## Comments

- Comment on why, not what. Don't restate what the code already says.
- No block-style section headers (`# ====`, `# ----`). Use a single `# --- Section name` line to divide major sections.
- Keep file headers to 1-2 lines describing the script's purpose. Skip author/date/license boilerplate.
- Don't add comments to self-explanatory functions. A good function name eliminates the need for a doc comment.

## Functions

- Prefix private/internal functions with `_` (e.g., `_link_item`, `_resolve_path`)
- Prefix command implementations with `cmd_` (e.g., `cmd_install`, `cmd_status`)
- Use descriptive names. `resolve_chain` is better than `resolve` with a comment explaining what it resolves.
- Define helpers below the functions that call them when ordering doesn't matter for readability.

## Variables

- Use `local` by default inside functions
- `SCREAMING_SNAKE_CASE` for globals and constants
- Always quote variable expansions: `"${var}"` not `$var`
- Prefer `"${var:-default}"` for defaults over separate conditional checks

## Structure

- Prefer `[[ ]]` over `[ ]` for conditionals
- Use `$(...)` for command substitution, never backticks
- Use `readonly` for constants that shouldn't change
- Prefer `printf` over `echo` for anything non-trivial
- Handle both GNU and BSD variants for tools like `sed` and `date` when portability matters

## Error handling

- Use `die` or a similar fatal-error function instead of bare `exit 1` with an inline message
- Validate required arguments early and fail fast with clear messages
- Use `||` guards for commands that might fail under `set -e` when failure is expected
