---
name: codex-config-coach
description: Use when improving Codex steering, token/context cost, hooks, skills, plugins, MCPs, or dotty-managed config.
---

# Codex Config Coach

Turn real session friction into measured, durable steering updates. Keep this skill generic; route private, machine-specific, or employer-specific policy to the later dotty-chain repo that owns it.

## Workflow

1. Identify concrete friction: repeated correction, rejected assumption, brittle workaround, token waste, slow tool path, or hook/config breakage. Do not add config for a single unusual task.
2. Inspect the routing context before editing: repo `AGENTS.md`, tracked `home/.ruler/`, `home/.codex/`, `home/.claude/`, nearby skills, and live generated files only to confirm runtime state. For generated skills, use `.dotty-managed-skills.tsv` or the owner manifest to find the tracked source.
3. Audit cost and determinism early. Treat always-active instructions, long skill text, enabled plugins, active MCPs, runtime-injected tools, duplicate reads, broad searches, manual multi-source gathering, and polling as suspect until they prove useful. Prefer CLIs, repo helpers, deferred tool discovery, or skill-triggered surfaces over always-on MCP/plugin context when the workflow is occasional.
4. Measure when practical. For skills or plugins, run `plugin-eval analyze <path> --format markdown`; add `plugin-eval explain-budget <path> --format markdown` when token cost is part of the concern. For MCP changes, capture enabled server count, exposed tool count, and approximate `tools/list` schema bytes before and after when the server can report them cheaply. Use scores and counts as evidence, not as the only objective.
5. Pick the narrowest durable surface: `AGENTS.md` for broad routing, an existing skill for workflow-specific behavior, deferred references for detailed procedure, helper scripts for deterministic repeated command logic, and one-time `.dotty/cleanups/` tasks when a migration must remove or reshape existing live artifacts.
6. Apply narrow, low-risk updates directly when the user asks for recommended updates or has accepted the direction. When asked whether updates are worth making, make clear unambiguous fixes in the same turn instead of returning a recommendation for confirmation. Propose first when ownership is ambiguous, impact is high, or evidence is weak.
7. At closeout after a heavy or correction-heavy workflow, do a lightweight token/determinism pass without waiting for the user to ask. Look for repeated tool sequences, noisy helper output, manual fallback paths, schema mismatches, or source data that should be filtered before reaching the model.
8. Call out clear token, supervision, or workflow simplification opportunities when they appear, even if they are not the main requested change. Keep the note brief and actionable.
9. Finish through the target repo workflow: edit tracked sources, run required regeneration such as `dotty update`, run checks, and commit/push when repo instructions require it.

Load `references/audit-details.md` for tool adoption, helper extraction, MCP/plugin surface audits, transcript lookup, high-impact measurement, or response templates.

## Response Shape

For config-improvement analysis, use the response template in `references/audit-details.md`.
