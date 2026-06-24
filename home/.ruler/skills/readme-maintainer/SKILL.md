---
name: readme-maintainer
description: Use when creating, auditing, or updating README/repo landing pages, setup docs, CLI docs, contributor notes, or README drift checks.
---

# README Maintainer

Treat the README as the repo landing page, not the complete manual. Make the first useful path obvious and push deep reference material into linked docs when the repo supports that shape.

## Paved Path

There is no universal tool that keeps arbitrary repo READMEs well-structured and current. Use established docs practice as the default: GitHub and Google README guidance for landing-page basics, Diataxis for separating user needs, and repo-local checks for freshness. Linters and generators are supporting tools, not structure owners.

For command-heavy README patterns, template/generator limits, and a large CLI stress case, read `references/readme-patterns.md`.

## Workflow

1. Inspect repo truth before editing.
   - Read `README.md`, `AGENTS.md`, nearby docs, package manifests, scripts, CLI help, tests, and existing check commands.
   - Look specifically for README drift checks, such as tests that assert documented flags, generated help, install commands, or setup paths.
   - Preserve stronger local conventions when they conflict with generic README templates.
2. Identify the README job.
   - Decide whether the README primarily serves first install, daily use, CLI usage, contribution, operations, library consumption, or repo navigation.
   - Check whether the first screen says what the repo is, who it is for, and what to do first.
   - Avoid guessing at audience when repo docs, package metadata, or scripts answer it.
3. Choose the smallest useful structure.
   - Prefer: overview, install or quick start, daily use or common tasks, layout, links to deeper docs.
   - For CLI repos, keep the top path task-oriented and split exhaustive options, hooks, config, troubleshooting, or maintainer workflows into later reference sections or `docs/`.
   - Do not impose generic template sections that do not fit the repo.
4. Edit for scanability and freshness.
   - Put each command block next to why or when to run it.
   - Avoid giant command dumps unless the section is intentionally a quick reference.
   - Split trailing-comment command blocks by workflow or move explanation into prose when they would be too wide in a normal GitHub viewport.
   - Use bullets for peer items and tables only for comparison or reference.
   - Keep headings concrete and sentence case unless the repo uses another convention.
   - Wrap exact commands, paths, files, packages, flags, and code identifiers in backticks.
5. Validate and finish.
   - Verify documented commands against their source of truth before rewriting around them.
   - Run the smallest repo check that covers the README claim; include markdown/prose checks when available.
   - If commands, setup, generated config, or repo layout changed, update the README or linked docs in the same change.
   - Summarize the structural change and what was verified.

## Audit Checklist

- The opening paragraph explains the repo without assuming prior context.
- The first actionable path is obvious.
- Setup and daily-use commands are separated.
- Long or rare details link to deeper docs.
- Headings form a usable table of contents when rendered.
- Code blocks are not detached from their explanation.
- Lists contain parallel items at the same level of detail.
- The README does not duplicate large chunks of docs that will drift.
- The documented commands exist and still mean what the README says.
- Repo-local README freshness checks are preserved and run when relevant.
