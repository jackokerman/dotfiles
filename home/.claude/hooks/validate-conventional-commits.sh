#!/bin/bash
# PreToolUse hook: enforce conventional commit format in dotty-managed repos.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only check git commit commands
if ! echo "$COMMAND" | grep -qE '\bgit commit\b'; then
  exit 0
fi

# Only enforce in dotty-managed repos (personal repos, dotfiles, overlays)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
REPO_ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || echo "")
if [[ -z "$REPO_ROOT" ]] || [[ ! -f "$REPO_ROOT/.dotty/config" ]]; then
  exit 0
fi

# Extract the first line of the commit message.
# Handle heredoc pattern first (Claude Code convention):
#   git commit -m "$(cat <<'EOF'
#   message here
#   EOF
#   )"
FIRST_LINE=""
if echo "$COMMAND" | grep -q "<<"; then
  FIRST_LINE=$(echo "$COMMAND" | sed -n "/<<.*EOF/,/EOF/{/<<.*EOF/d;/EOF/d;p;}" | sed '/^$/d' | head -1 | sed 's/^[[:space:]]*//')
fi

# Fall back to -m "message" or -m 'message'
if [[ -z "$FIRST_LINE" ]]; then
  FIRST_LINE=$(echo "$COMMAND" | sed -nE 's/.*-m[[:space:]]+"([^"]+)".*/\1/p' | head -1)
fi
if [[ -z "$FIRST_LINE" ]]; then
  FIRST_LINE=$(echo "$COMMAND" | sed -nE "s/.*-m[[:space:]]+'([^']+)'.*/\1/p" | head -1)
fi

# If we can't extract the message, allow it (fail open)
if [[ -z "$FIRST_LINE" ]]; then
  exit 0
fi

FIRST_LINE=$(echo "$FIRST_LINE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Validate conventional commit format
if ! echo "$FIRST_LINE" | grep -qE '^(feat|fix|refactor|docs|test|chore|style)(\(.+\))?!?: .+'; then
  echo "Commit message doesn't follow conventional commit format." >&2
  echo "Expected: <type>: <description>" >&2
  echo "Types: feat, fix, refactor, docs, test, chore, style" >&2
  echo "Got: $FIRST_LINE" >&2
  exit 2
fi

exit 0
