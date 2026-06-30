---
id: 2026-06-26-investigate-uncommitted-agent-changes-piling-up-in-dotfiles
title: Investigate uncommitted agent changes piling up in dotfiles
state: inbox
createdAt: 2026-06-26T22:02:36.944Z
updatedAt: 2026-06-30T03:12:34.104Z
---

# Investigate uncommitted agent changes piling up in dotfiles

Investigate how to make uncommitted or untracked dotfiles changes more visible and actionable when agents or helper tools modify them.

Key questions:

- Where changes most often accumulate: public dotfiles, private overlays, generated/live linked outputs, or multiple places.
- Which workflows leave changes behind: agents, local tools, dotty update/link flows, generated files, or repo checks.
- Whether the fix should be steering, status checks, a follow-up prompt, shell helper, or repo-level validation.
- How to handle unrelated dirty files that predate an agent session.

The desired outcome is first to identify a practical improvement path, then implement it in the owning repo or workflow.
