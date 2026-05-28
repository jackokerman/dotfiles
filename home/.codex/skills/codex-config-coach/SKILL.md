---
name: codex-config-coach
description: Use when the user wants to improve Codex steering, turn corrections or "why did you do that?" moments into durable config, decide where guidance belongs in a dotty-managed setup, inspect current or explicitly requested previous Codex sessions for reusable patterns, or update tracked Codex skills, agents, AGENTS.md, hooks, or config.
---

# Codex Config Coach

Help improve Codex behavior by turning real session friction into small, durable steering updates. Keep this generic and setup-aware: understand dotty-managed layered config, but do not embed private overlay policy in this skill.

## Workflow

1. Identify the behavior to improve.
   - Look for concrete correction signals: "why did you do X?", "can we do Y instead?", repeated user redirection, rejected assumptions, or a manual workaround the user had to explain.
   - Separate reusable steering from one-off task feedback. Do not add config for a single unusual case.
2. Inspect the local routing context before choosing a target.
   - Read the relevant repo's `AGENTS.md`, `README.md`, tracked `home/.codex/` sources, and nearby skill files before editing.
   - In dotty-managed repos, treat tracked sources under `home/` as authoritative and live `~/.codex` files as generated runtime state unless local instructions say otherwise.
   - Route generic personal behavior to the public base dotfiles repo. Route private, machine-specific, employer-specific, or overlay-only behavior to the later dotty-chain repo that owns those concerns.
3. Pick the narrowest durable surface.
   - Use `AGENTS.md` for always-on preferences and broad routing rules.
   - Use an existing skill when the behavior applies only to that workflow.
   - Add or update a helper script only when deterministic inspection or repeated command logic is needed.
   - Avoid broad new policy, speculative guardrails, fallback paths, or duplicate guidance.
4. Propose before mutating unless the user explicitly asked to apply the update.
   - State the observed friction, the proposed steering change, and the target file or skill.
   - If multiple targets are plausible, recommend one and explain the routing briefly.
5. Apply and finish using the target repo's workflow.
   - Use tracked sources, not generated runtime files.
   - Run `dotty update` after tracked Codex config, skill, agent, or hook changes when the repo instructions require it.
   - Run the repo's checks, commit with a conventional commit, and push when the repo requires that for completion.

## Transcript Lookup

Default to the current visible session. Do not read stored Codex sessions unless the user explicitly asks for previous, latest, or historical session context.

When explicit lookup is useful, run the bundled helper from this skill directory:

```bash
bun run scripts/codex-session-snippets.ts --latest
bun run scripts/codex-session-snippets.ts --thread <thread-id> --query "why did you"
```

Use helper output as evidence, not as a replacement for judgment. Pull only the relevant snippets into context and avoid dumping full transcripts.

## Good Updates

- Add one sentence to a workflow skill after the same correction happened twice.
- Move a generic preference from an overlay into the base dotfiles repo when it is reusable outside work.
- Add a short routing rule when agents repeatedly edit generated `~/.codex` state instead of tracked sources.
- Decline to edit config when the correction is specific to one task or already covered by existing instructions.

## Response Shape

For config-improvement analysis, use this shape:

1. Friction observed.
2. Durable rule, if any.
3. Target location.
4. Proposed edit or applied change.
5. Validation and follow-up workflow.
