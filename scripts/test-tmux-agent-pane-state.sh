#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/home/.config/tmux/agent-pane-state.sh"

run_case() {
    local name="$1" agent="$2" expected="$3" input="$4" actual=""

    actual=$(printf '%s' "$input" | "$TARGET_SCRIPT" infer-tail "$agent")
    if [[ "$actual" == "$expected" ]]; then
        printf '[tmux-test] pass: %s\n' "$name"
        return 0
    fi

    printf '[tmux-test] fail: %s\n' "$name" >&2
    printf '[tmux-test] expected: %q\n' "$expected" >&2
    printf '[tmux-test] actual: %q\n' "$actual" >&2
    exit 1
}

run_case \
    "codex question prompt stays waiting" \
    "codex" \
    "waiting" \
    "$(cat <<'EOF'
• I have enough repo context to plan Priority 3 cleanly, but one scope choice changes the public surface area.

  Question 1/1 (1 unanswered)
  How far should Priority 3 go on explicit slug skipping?

  › 1. Fallback only (Recommended)  Add deterministic fallback on provider failure/timeout; no new CLI/config surface for skipping LLM slugging yet.
    2. Add CLI switch               Include a new user-facing flag to force heuristic slugging and bypass provider slug generation.
    3. Add config + CLI             Include a persistent default plus an override, expanding scope into config work now.
    4. None of the above            Optionally, add details in notes (tab).

  tab to add notes | enter to submit answer | esc to interrupt
EOF
)"

run_case \
    "codex working line stays working" \
    "codex" \
    "working" \
    "$(cat <<'EOF'
• Working (1m 35s • esc to interrupt)

› Write tests for @filename
EOF
)"

run_case \
    "plan confirmation prompt stays waiting" \
    "codex" \
    "waiting" \
    "$(cat <<'EOF'
  Implement this plan?

› 1. Yes, implement this plan  Switch to Default and start coding.
  2. No, stay in Plan mode     Continue planning with the model.

  Press enter to confirm or esc to go back
EOF
)"

run_case \
    "codex idle prompt footer stays neutral" \
    "codex" \
    "" \
    "$(cat <<'EOF'


› Audit this parser

  gpt-5.4 xhigh · 71% left · /workspace/project
EOF
)"

run_case \
    "completed transcript plus idle footer stays neutral" \
    "codex" \
    "done" \
    "$(cat <<'EOF'
• Running Stop hook

Stop hook (completed)


› Audit this parser

  gpt-5.4 xhigh · 78% left · ~/src/project
EOF
)"

run_case \
    "codex working beats an older completed stop hook" \
    "codex" \
    "working" \
    "$(cat <<'EOF'
• Running Stop hook

Stop hook (completed)

• Working (2m 27s • esc to interrupt)


› Audit this parser

  gpt-5.4 xhigh · 78% left · ~/src/project
EOF
)"

run_case \
    "codex working beats idle prompt footer" \
    "codex" \
    "working" \
    "$(cat <<'EOF'
• I’m updating the tests now to lock down the new behavior explicitly.

• Working (2m 27s • esc to interrupt)


› Audit this parser

  gpt-5.4 xhigh · 78% left · ~/src/project
EOF
)"

run_case \
    "approval prompt stays waiting" \
    "claude" \
    "waiting" \
    "$(cat <<'EOF'
Would you like to run the following command?
Press enter to confirm or esc to cancel
EOF
)"

run_case \
    "question navigation prompt stays waiting" \
    "codex" \
    "waiting" \
    "$(cat <<'EOF'
  Question 2/3 (2 unanswered)
  What should be the long-term source of truth for overlapping frontend guidance?

  tab to add notes | enter to submit answer | ←/→ to navigate questions | esc to interrupt
EOF
)"

run_case \
    "hyphenated approval check stays neutral" \
    "codex" \
    "" \
    "$(cat <<'EOF'
    *  codeowner-approval-v2                                   https://example.com/code-re...
EOF
)"

run_case \
    "neutral tail stays empty" \
    "codex" \
    "" \
    "$(cat <<'EOF'
• Explored
  └ Read main.ts, exec.ts, types.ts
EOF
)"
