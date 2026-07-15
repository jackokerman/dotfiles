---
id: 2026-07-15-build-writing-style-example-corpus-and-analysis-workflow
title: Build writing-style example corpus and analysis workflow
state: inbox
createdAt: 2026-07-15T04:55:22.566Z
updatedAt: 2026-07-15T04:55:22.566Z
---

# Build writing-style example corpus and analysis workflow

## Plan

Follow up on repeated drafting corrections where generated Slack, PR description, PR comment, Jira comment, and review-request text sounded too polished or formal compared with the user's normal workplace voice.

Context:
- A small durable update has been added to the `writing-style` skill to prefer lightly cleaned-up spoken workplace prose for Slack, PR descriptions, PR comments, Jira comments, review comments, and review requests.
- The broader improvement should be evidence-based instead of adding many ad hoc rules from a single session.

Scope to investigate:
- Collect a small set of approved final drafts and rejected rewrites from real sessions or user-provided examples.
- Analyze recurring traits: contractions, first-person framing, acceptable casualness, disliked phrases, how much technical detail belongs in PR comments, and when document-style prose is still appropriate.
- Decide whether examples should live in a deferred `writing-style` reference file, a local private note, or another source that does not add always-loaded context.
- Consider whether any off-the-shelf writing/style tooling helps, but prefer a small curated example corpus unless a tool clearly improves personal voice matching.
- Update `writing-style` only with rules that repeat across examples.

Acceptance criteria:
- A proposed storage location and format for approved examples.
- A short analysis of common style rules based on examples, not guesses.
- A minimal skill update or explicit decision that the existing skill is sufficient.
