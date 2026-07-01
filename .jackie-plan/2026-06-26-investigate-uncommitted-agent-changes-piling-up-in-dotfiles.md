---
id: 2026-06-26-investigate-uncommitted-agent-changes-piling-up-in-dotfiles
title: Investigate uncommitted agent changes piling up in dotfiles
state: inbox
createdAt: 2026-06-26T22:02:36.944Z
updatedAt: 2026-06-30T03:12:34.104Z
---

# Investigate uncommitted agent changes piling up in dotfiles

## Plan

## Context

When working on dotfiles, another tool or agent may modify tracked or untracked files without committing them. Those changes can pile up unnoticed, which makes later dotfiles work harder to reason about and risks losing track of which agent or workflow caused each change.

## Goal

Investigate how to make uncommitted or untracked dotfiles changes more visible and actionable when agents or helper tools modify them.

## Questions to answer

- Where does this most often happen: the public dotfiles repo, private overlay repos, generated/live linked outputs, or multiple places?
- Which workflows are leaving changes behind: Codex agents, other local tools, dotty update/link flows, generated files, or repo checks?
- Should the fix be stronger agent steering, a pre/post-run status check, a `jp`/dotty follow-up prompt, a shell helper, or repo-level validation?
- What should happen when unrelated dirty files already exist before an agent starts work?
- What is the smallest useful detection path that avoids noisy compatibility layers or speculative automation?

## Preserve

- The core pain is not just dirty git state; it is losing provenance and confidence when changes accumulate across agent/tool runs.
- The desired outcome is exploratory first: identify a practical improvement path, then implement it in the owning repo or workflow.
- This feels worth addressing sooner rather than leaving as a vague annoyance.

## Agent handoff

# Investigate uncommitted agent changes piling up in dotfiles

Investigate how to make uncommitted or untracked dotfiles changes more visible and actionable when agents or helper tools modify them.

Key questions:

- Where changes most often accumulate: public dotfiles, private overlays, generated/live linked outputs, or multiple places.
- Which workflows leave changes behind: agents, local tools, dotty update/link flows, generated files, or repo checks.
- Whether the fix should be steering, status checks, a follow-up prompt, shell helper, or repo-level validation.
- How to handle unrelated dirty files that predate an agent session.

The desired outcome is first to identify a practical improvement path, then implement it in the owning repo or workflow.
