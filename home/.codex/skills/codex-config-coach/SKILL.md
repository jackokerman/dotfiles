---
name: codex-config-coach
description: Use when improving Codex steering, auditing skill/config token use, turning repeated corrections into durable config, or choosing AGENTS, skill, plugin, hook, or config surfaces in a dotty-managed setup.
---

# Codex Config Coach

Help improve Codex behavior by turning real session friction into measured, durable steering updates. Keep this generic and setup-aware: understand dotty-managed layered config, but do not embed private overlay policy in this skill.

## Workflow

1. Identify the behavior to improve.
   - Look for concrete correction signals: "why did you do X?", "can we do Y instead?", repeated user redirection, rejected assumptions, or a manual workaround the user had to explain.
   - Separate reusable steering from one-off task feedback. Do not add config for a single unusual case.
   - For agent/tooling workflow adoption plans, look for repeated clarification around off-the-shelf versus custom structure, artifact ownership, global versus repo-local install scope, multi-machine support, opt-in and rollback behavior, day-to-day commands, and concrete verification. Treat those as planning-quality friction, not just implementation details.
   - When token or tool efficiency is part of the ask, audit avoidable tool usage separately: blocked commands, reversed tool choices, duplicate reads/checks, unnecessary API calls, and polling that did not change a decision. Prefer updating the specific workflow skill that caused the waste; add broad guidance only when the pattern is reusable across workflows.
2. Inspect the local routing context before choosing a target.
   - Read the relevant repo's `AGENTS.md`, `README.md`, tracked `home/.codex/` sources, and nearby skill files before editing.
   - In dotty-managed repos, treat tracked sources under `home/` as authoritative and live `~/.codex` files as generated runtime state unless local instructions say otherwise.
   - Route generic personal behavior to the public base dotfiles repo. Route private, machine-specific, employer-specific, or overlay-only behavior to the later dotty-chain repo that owns those concerns.
3. Measure the candidate surface when practical.
   - For a Codex skill or plugin, run `plugin-eval analyze <path> --format markdown` before recommending structural changes.
   - When token usage is part of the concern, also run `plugin-eval explain-budget <path> --format markdown`.
   - Use the report as evidence, not as a replacement for judgment. Classify findings as structural, trigger/routing, token budget, behavioral, or context-layering issues.
   - Do not optimize for static token score alone. A longer skill can be correct if it improves first-pass success, avoids risky behavior, or prevents repeated user correction.
4. Pick the narrowest durable surface.
   - Use `AGENTS.md` for always-on preferences and broad routing rules.
   - Use an existing skill when the behavior applies only to that workflow.
   - Use deferred reference files for detailed procedures, examples, or context that should not load on every turn.
   - Add or update a helper script only when deterministic inspection or repeated command logic is needed.
   - Avoid broad new policy, speculative guardrails, fallback paths, or duplicate guidance.
   - When auditing later dotty-chain repos, check for skill-name overlap with the base dotfiles skills and for generic guidance nested inside host-specific skills.
5. Use a measurement ladder for high-impact changes.
   - Light: static `plugin-eval analyze` and `plugin-eval explain-budget` reports.
   - Medium: define two or three pressure scenarios that should pass after the steering change and fail or require correction before it.
   - Heavy: initialize and run `plugin-eval` benchmarks only with explicit approval, because they create `.plugin-eval/` artifacts and run real Codex sessions.
   - When comparing alternatives, prefer blind before/after comparison and keep the simpler version if outcomes are equivalent.
6. Apply narrow, low-risk updates directly when the user asks for recommended updates, asks to make the changes, or has already accepted the proposed direction.
   - Propose instead of editing when the target is ambiguous, the change is high-impact, the evidence is weak, or the user explicitly asks to review the recommendation first.
   - State the observed friction, the steering change, and the target file or skill.
   - If multiple targets are plausible, recommend one and explain the routing briefly.
   - Apply only changes backed by concrete session evidence, local config inspection, and a clear reason they should make future agent behavior more reliable or deterministic.
7. Apply and finish using the target repo's workflow.
   - Use tracked sources, not generated runtime files.
   - Run `dotty update` after tracked Codex config, skill, agent, or hook changes when the repo instructions require it.
   - Run the repo's checks, commit with a conventional commit, and push when the repo requires that for completion.

## Transcript Lookup

Default to the current visible session. Do not read stored Codex sessions unless the user explicitly asks for previous, latest, or historical session context.

When explicit lookup is useful, run the tracked transcript helper:

```bash
codex-session-snippets --latest
codex-session-snippets --thread <thread-id> --query "why did you"
```

Use helper output as evidence, not as a replacement for judgment. Pull only the relevant snippets into context and avoid dumping full transcripts.

## Good Updates

- Add one sentence to a workflow skill after the same correction happened twice.
- Add a workflow-adoption checklist when planning repeatedly missed install scope, artifact ownership, reversibility, or day-to-day usage questions before implementation.
- Move a generic preference from an overlay into the base dotfiles repo when it is reusable outside work.
- Add a short routing rule when agents repeatedly edit generated `~/.codex` state instead of tracked sources.
- Split a large skill by moving examples or detailed procedure into a reference file when `plugin-eval` shows excessive invoke budget and the detail is not needed on every use.
- Add pressure scenarios before changing a high-impact skill whose purpose is behavioral compliance rather than static reference lookup.
- Decline to edit config when the correction is specific to one task or already covered by existing instructions.

## Response Shape

For config-improvement analysis, use this shape:

1. Friction observed.
2. Durable rule, if any.
3. Target location.
4. Proposed edit or applied change.
5. Validation and follow-up workflow.
6. Tool-use audit and token-saving opportunities.
