# Audit Details

## Tool Adoption And Helper Extraction

For tooling adoption plans, settle off-the-shelf versus custom structure, ownership, global versus repo-local scope, multi-machine support, opt-in and rollback behavior, day-to-day commands, and verification.

For helper extraction or public-repo plans, also settle publication privacy, reachable Git history, install/update ownership, dirty-worktree handling, rollback, and downstream rollout. Verify tool availability and package-manager ownership on each relevant machine class. Treat package-manager cleanup, prune, uninstall, and sync modes that remove untracked tools as destructive.

When moving or capturing plan artifacts from a private, local, or later-overlay root into a public repo, rewrite source metadata and prose to the generic public purpose before staging. If that would lose necessary context or change the work's meaning, keep the artifact in the private or later-overlay root instead.

When a workflow already has a tracked helper or client, prefer extending that helper and its tests over teaching Codex more ad hoc fallback commands. Treat raw API probes and runtime bundle inspection as last-resort discovery steps, then capture the confirmed contract back into the helper immediately.

When a repo-local helper grows its own runtime, dependency, verification, or release-cadence needs, evaluate extracting it into a standalone repo or package instead of continuing to expand dotfiles. Favor extraction when the helper is likely to back multiple surfaces such as a CLI, Raycast extension, or other automation entrypoints.

When a standalone tool still needs dotty integration, keep dotfiles to bootstrap and routing glue, then audit the full dotty chain for later overlays that regenerate the same live outputs. After `dotty update`, verify generated indexes such as `~/.codex/skills/.dotty-managed-skills.tsv` and `~/.claude/skills/.dotty-managed-skills.tsv` point at the standalone source, not a copied dotfiles source.

## Context Surface Audit

When a session exposes token or latency pressure, inspect always-loaded instructions, invoked skills, enabled plugins, configured MCP servers, runtime-injected MCP servers, and repeated tool sequences.

Prefer lower-context alternatives when they preserve the workflow:

- A CLI or tracked helper beats an always-on MCP for repeatable command-like work.
- A skill-triggered or deferred tool beats an always-loaded plugin when the workflow is occasional.
- A repo-local source module beats generic runtime logic when the concept is tied to one launcher, company, machine class, or private workflow.
- A short routing rule beats broad examples in `AGENTS.md`; detailed examples belong in deferred references.

For MCP/plugin changes, compare tracked fragments, `codex doctor`, runtime launcher behavior, and CLI equivalents. Recommend disabling or deferring a surface only with a clear replacement path and evidence it is not needed in most sessions.

When an MCP server can report its tools cheaply, quantify the surface area instead of relying only on config diffs: enabled server count, exposed tool count, raw `tools/list` bytes, and schema/description bytes are useful before/after proxies for model-facing context. If a generator or config file can reintroduce a broad MCP surface, add a regression check that proves the default stays empty, deferred, or opt-in.

## Measurement Ladder

- Light: static `plugin-eval analyze` and `plugin-eval explain-budget` reports.
- MCP-specific light: compare `codex mcp list` output plus `tools/list` tool counts and schema bytes for any changed MCP servers.
- Medium: define two or three pressure scenarios that should pass after the steering change and fail or require correction before it.
- Heavy: initialize and run `plugin-eval` benchmarks only with explicit approval, because they create `.plugin-eval/` artifacts and run real Codex sessions.
- When comparing alternatives, prefer blind before/after comparison and keep the simpler version if outcomes are equivalent.

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
- Recommend extracting a helper from dotfiles when its tests, dependencies, or release needs create repo-wide drag that is unrelated to most dotfiles changes.
- Add pressure scenarios before changing a high-impact skill whose purpose is behavioral compliance rather than static reference lookup.
- Add a cheap regression test when removing a broad default MCP/plugin surface, especially if a generated fragment or sync hook could bring it back.
- Decline to edit config when the correction is specific to one task or already covered by existing instructions.

## Response Shape

For config-improvement analysis, use this shape:

1. Friction observed.
2. Durable rule, if any.
3. Target location.
4. Proposed edit or applied change.
5. Validation and follow-up workflow.
6. Tool-use audit and token-saving opportunities.
