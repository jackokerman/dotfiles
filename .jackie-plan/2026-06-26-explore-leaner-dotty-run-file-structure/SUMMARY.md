---
id: 2026-06-26-explore-leaner-dotty-run-file-structure
title: Explore leaner dotty run file structure
state: inbox
createdAt: 2026-06-26T15:53:34.972Z
updatedAt: 2026-06-26T15:53:34.972Z
---

# Summary

## Goal
Decide whether dotty run files should stay as thin orchestration entrypoints that delegate real logic to separate runnable scripts, and identify any other worthwhile run-file structure improvements.

## Why
The current instinct is that dotty run files should be easier to grok and organize if most substantive logic lives in separately invokable scripts. That would also make the logic easier to test and reuse outside the run-file entrypoint.

## Exploration First
Before changing structure broadly, inspect the existing dotty run files and classify what kinds of logic they currently hold.

Questions to answer during exploration:
- Which run files are currently carrying enough logic that extraction would materially improve readability?
- Which logic naturally wants to become a separate script with a direct invocation surface?
- Where would extraction improve testability or local debugging, versus just adding indirection?
- Are there recurring run-file problems beyond size, such as mixed concerns, inconsistent conventions, unclear naming, or awkward argument handling?
- Is there a small set of conventions for thin run files that would make the whole system more legible?

## Desired Outcome
Produce a concrete recommendation for dotty run-file structure, including:
- when to keep logic inline versus extract it
- what script boundaries make sense
- any naming or organization conventions worth standardizing
- a prioritized list of candidate follow-up refactors, if the exploration supports them

## Non-Goals
Do not assume every run file needs extraction.
Do not optimize for abstract flexibility without a concrete maintenance or testing win.
