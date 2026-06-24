---
name: codex-config-coach
description: Use when improving Codex steering, token/context cost, hooks, skills, plugins, MCPs, or dotty-managed config.
---

# Codex Config Coach

Turn real session friction into measured, durable steering updates. Keep this skill generic; route private, machine-specific, or employer-specific policy to the later dotty-chain repo that owns it.

## Workflow

1. Identify concrete friction: repeated correction, rejected assumption, brittle workaround, token waste, slow tool path, or hook/config breakage. Do not add config for a single unusual task.
2. Inspect the routing context before editing: repo `AGENTS.md`, tracked `home/.ruler/`, `home/.codex/`, `home/.claude/`, nearby skills, and live generated files only to confirm runtime state. For generated skills, use `.dotty-managed-skills.tsv` or the owner manifest to find the tracked source.
3. Audit cost early. Treat always-active instructions, long skill text, enabled plugins, active MCPs, runtime-injected tools, duplicate reads, broad searches, and polling as suspect until they prove useful. Prefer CLIs, repo helpers, deferred tool discovery, or skill-triggered surfaces over always-on MCP/plugin context when the workflow is occasional.
4. Measure when practical. For skills or plugins, run `plugin-eval analyze <path> --format markdown`; add `plugin-eval explain-budget <path> --format markdown` when token cost is part of the concern. Use scores as evidence, not as the only objective.
5. Pick the narrowest durable surface: `AGENTS.md` for broad routing, an existing skill for workflow-specific behavior, deferred references for detailed procedure, and helper scripts for deterministic repeated command logic.
6. Apply narrow, low-risk updates directly when the user asks for recommended updates or has accepted the direction. Propose first when ownership is ambiguous, impact is high, or evidence is weak.
7. Finish through the target repo workflow: edit tracked sources, run required regeneration such as `dotty update`, run checks, and commit/push when repo instructions require it.

Load `references/audit-details.md` for tool adoption, helper extraction, MCP/plugin surface audits, transcript lookup, high-impact measurement, or response templates.

## Response Shape

For config-improvement analysis, use the response template in `references/audit-details.md`.
