---
name: readme-maintainer
description: Use when writing a new README from scratch, creating, auditing, or updating README/repo landing pages, setup docs, CLI docs, contributor notes, AGENTS/repo steering docs, or docs drift checks.
---

# README Maintainer

Treat the README as the repo landing page, not the complete manual. Make the first useful path obvious and push deep reference material into linked docs when the repo supports that shape.

Use this skill as the repo documentation freshness pass, not only as prose style guidance. When a behavior change affects setup, commands, generated outputs, repo layout, validation, or contributor workflow, audit the README plus the adjacent docs and repo steering surfaces that describe that behavior, such as `AGENTS.md`, `CONTRIBUTING.md`, `docs/`, examples, CLI help, completions, and test maps.

## Paved Path

There is no universal tool that keeps arbitrary repo READMEs well-structured and current. Use established docs practice as the default: GitHub and Google README guidance for landing-page basics, Diataxis for separating user needs, and repo-local checks for freshness. Linters and generators are supporting tools, not structure owners.

For command-heavy README patterns, template/generator limits, and a large CLI stress case, read `references/readme-patterns.md`.

## Bootstrap Mode

When a repo has no useful README, write one from repo truth instead of asking for a template. Start from this lightweight shape and remove sections that do not fit:

- Overview: what the repo does, who it is for, and why it exists.
- Install or quick start: the shortest path to a working result.
- Common tasks: the commands or workflows users repeat.
- Configuration: only the settings needed to start or understand routing.
- Development: the smallest contributor check path.
- Deeper docs: links for reference material that would make the README too long.

Treat this as scaffolding, not a required template. Prefer the repo's existing package metadata, CLI help, tests, docs, and scripts over generic section names.

## Workflow

1. Inspect repo truth before editing.
   - Read `README.md`, `AGENTS.md`, nearby docs, package manifests, scripts, CLI help, completions, examples, tests, and existing check commands.
   - Look specifically for docs drift checks, such as tests that assert documented flags, generated help, install commands, setup paths, command lists, or test maps.
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
   - Do not hard-wrap Markdown prose solely to satisfy line-length checks. Treat long-line lint as a reason to inspect paragraph density, not as an automatic wrapping instruction.
   - Use bullets for peer items and tables only for comparison or reference.
   - Keep headings concrete and sentence case unless the repo uses another convention.
   - Wrap exact commands, paths, files, packages, flags, and code identifiers in backticks.
5. Validate and finish.
   - Verify documented commands against their source of truth before rewriting around them.
   - Run the smallest repo check that covers the README claim; include markdown/prose checks when available.
   - If commands, setup, generated config, repo layout, validation, or contributor workflow changed, update the README, linked docs, and repo steering surfaces in the same change.
   - If a code change intentionally leaves the README unchanged, briefly state why it did not affect the repo landing page, setup path, daily commands, or documented behavior.
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
- Adjacent docs and steering surfaces that describe the same behavior were checked and updated or explicitly ruled out.
- Repo-local README freshness checks are preserved and run when relevant.
