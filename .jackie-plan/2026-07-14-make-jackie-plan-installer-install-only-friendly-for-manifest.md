---
id: 2026-07-14-make-jackie-plan-installer-install-only-friendly-for-manifest
title: Make Jackie Plan installer install-only friendly for manifest-driven callers
state: inbox
createdAt: 2026-07-14T17:30:53.737Z
updatedAt: 2026-07-14T17:52:49.015Z
sourcePlan: 2026-06-26-design-config-driven-devtool-repo-management
---

# Make Jackie Plan installer install-only friendly for manifest-driven callers

## Plan

Update the Jackie Plan repo-owned installer so callers that already synchronized the checkout can run an install-only path without triggering a second Git fetch or fast-forward attempt.

## Context

The dotfiles devtools manifest now owns cloning and conservative fast-forward updates for `~/src/jackie-plan`, then dispatches `repo:scripts/install.sh`. That satisfies the dotfiles migration, but the current Jackie Plan `scripts/install.sh` still runs its own update step before linking the CLI, completion, and Codex plugin. The dotfiles dispatcher forces `GIT_TERMINAL_PROMPT=0`, so this is not interactive, but it leaves checkout update ownership duplicated across the sync layer and the repo installer.

## Desired outcome

Jackie Plan should expose a small, documented install-only mode or equivalent installer boundary that keeps the existing human-friendly default behavior while letting manifest-driven callers avoid redundant checkout updates. After that exists, the dotfiles manifest integration can use it without adding positional metadata or another checkout source of truth.
