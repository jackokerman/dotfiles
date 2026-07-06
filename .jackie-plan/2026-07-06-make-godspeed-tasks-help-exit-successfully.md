---
id: 2026-07-06-make-godspeed-tasks-help-exit-successfully
title: Make godspeed-tasks help exit successfully
state: complete
createdAt: 2026-07-06T01:43:21.974Z
updatedAt: 2026-07-06T02:18:05.152Z
sourcePlan: 2026-07-05-simplify-godspeedjs-client-types
---

# Make godspeed-tasks help exit successfully

## Plan

# Make godspeed-tasks help exit successfully

## Context

While verifying `2026-07-05-simplify-godspeedjs-client-types`, `godspeed-tasks --help` printed the compatibility CLI usage text but exited with status `2`.

This appears separate from the GodspeedJS client API shape migration: the command still resolves and prints the expected usage, and the current plan explicitly leaves broader `godspeed-tasks` compatibility work to a separate cleanup path.

## Suggested next step

In `/Users/jackokerman/src/godspeed-js`, decide whether `godspeed-tasks --help` should be treated as a successful help request and, if so, update the legacy compatibility CLI parser and tests so `--help` exits `0` without changing command behavior.
