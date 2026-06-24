---
name: codex-config-coach
description: Use when improving Codex steering, auditing skill/config token use, turning repeated corrections into durable config, or choosing AGENTS, skill, plugin, hook, or config surfaces in a dotty-managed setup.
---

# Codex Config Coach

Help improve Codex behavior by turning real session friction into measured, durable steering updates. Keep this generic and setup-aware: understand dotty-managed layered config, but do not embed private overlay policy in this skill.

## Core Workflow

1. Identify the behavior to improve.
   - Look for concrete correction signals: repeated user redirection, rejected assumptions, manual workarounds, or avoidable token/tool waste.
   - Separate reusable steering from one-off task feedback. Do not add config for a single unusual case.
   - When token or tool efficiency is part of the ask, audit avoidable tool usage separately: blocked commands, reversed tool choices, duplicate reads/checks, unnecessary API calls, and polling that did not change a decision.
2. Inspect the local routing context before choosing a target.
   - In dotty-managed repos, treat tracked sources under `home/` as authoritative and live `~/.codex` files as generated runtime state unless local instructions say otherwise.
   - Route generic personal behavior to the public base dotfiles repo. Route private, machine-specific, employer-specific, or overlay-only behavior to the later dotty-chain repo that owns those concerns.
   - Read [references/routing-and-surfaces.md](references/routing-and-surfaces.md) when target ownership, generated skill sources, live runtime debugging, or tool-adoption planning matters.
3. Measure the candidate surface when practical.
   - For a Codex skill or plugin, run `plugin-eval analyze <path> --format markdown` before recommending structural changes.
   - When token usage is part of the concern, also run `plugin-eval explain-budget <path> --format markdown`.
   - Use the report as evidence, not as a replacement for judgment. Do not optimize for static token score alone.
   - Read [references/measurement.md](references/measurement.md) for pressure scenarios, benchmark levels, and token-audit details.
4. Pick the narrowest durable surface.
   - Use `AGENTS.md` for always-on preferences and broad routing rules.
   - Use an existing skill when the behavior applies only to that workflow.
   - Use deferred reference files for detailed procedures, examples, or context that should not load on every turn.
   - Add or update a helper script only when deterministic inspection or repeated command logic is needed.
   - Avoid broad new policy, speculative guardrails, fallback paths, or duplicate guidance.
5. Apply narrow, low-risk updates directly when the user asks for recommended updates, asks to make the changes, or has already accepted the proposed direction.
   - Propose instead of editing when the target is ambiguous, the change is high-impact, the evidence is weak, or the user explicitly asks to review the recommendation first.
   - State the observed friction, steering change, target file or skill, validation, and follow-up.
6. Finish using the target repo's workflow.
   - Use tracked sources, not generated runtime files.
   - Run `dotty update` after tracked Codex config, skill, agent, or hook changes when the repo instructions require it.
   - Run the repo's checks, commit with a conventional commit, and push when the repo requires that for completion.

## Transcript Lookup

Default to the current visible session. Do not read stored Codex sessions unless the user explicitly asks for previous, latest, or historical session context.

When explicit lookup is useful, read [references/transcripts.md](references/transcripts.md).

## Good Updates

Read [references/examples.md](references/examples.md) when deciding whether an edit is durable enough. Common good targets include a narrow workflow-skill sentence after repeated correction, moving examples into deferred references, or declining config edits when the correction is task-specific.

## Response Shape

For config-improvement analysis, cover:

1. Friction observed.
2. Durable rule, if any.
3. Target location.
4. Proposed edit or applied change.
5. Validation and follow-up workflow.
6. Tool-use audit and token-saving opportunities.
