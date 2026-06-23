---
name: readme-maintainer
description: Use when creating, auditing, restructuring, or updating README files and repo landing-page documentation, especially when making setup, daily-use, command, or layout information easier to scan and keep current across repos.
---

# README Maintainer

Use this skill when a README should become clearer, more accurate, or easier to navigate. Treat the README as the repo landing page, not the complete manual.

## Paved Path

There is no universal off-the-shelf tool that keeps arbitrary repo READMEs well-structured and current. Use established documentation practice as the default:

- GitHub README guidance: purpose, usage, contribution, and navigation for first-time visitors.
- Diataxis: separate tutorials, how-to guides, reference, and explanation instead of mixing them in one section.
- Write the Docs: write for the audience and keep docs task-oriented.
- Linters such as Vale or markdownlint catch mechanics; they do not decide audience, hierarchy, or what belongs in `docs/`.
- Generators such as `readme.so` can bootstrap a README, but avoid imposing generic template sections that do not fit the repo.

## Workflow

1. Identify the audience and job.
   - Determine whether the README is for first install, daily use, contribution, operations, or a library consumer.
   - Preserve repo-specific instructions and local conventions from `AGENTS.md`, existing docs, scripts, package metadata, and tests.
   - If the repo already has a stronger README convention, follow it.
2. Audit the current README.
   - Check whether the first screen says what the repo is, who it is for, and what to do first.
   - Look for command dumps, long paragraphs, repeated detail, mixed audiences, stale setup steps, and sections that duplicate deeper docs.
   - Verify command names against local scripts or package metadata before rewriting around them.
3. Choose a small structure.
   - Prefer a short landing-page shape: overview, install or quick start, daily use or common tasks, layout, links to deeper docs.
   - Use subheaders for multi-step setup flows when code blocks or paragraphs make numbered-list indentation hard to scan.
   - Keep rare, explanatory, subsystem, troubleshooting, and architecture detail in `docs/`; link to it from the README.
4. Edit for scanability.
   - Put each command block next to the reason to run it.
   - Use bullets for peer items and short tables only when comparison matters.
   - Avoid an undifferentiated command block unless the section is explicitly a quick reference.
   - Keep headings concrete and sentence case unless the repo uses another convention.
   - Wrap exact commands, paths, files, packages, flags, and code identifiers in backticks.
5. Keep the README current.
   - When setup commands, daily workflows, generated config, or repo layout change, update the README or linked docs in the same change.
   - If the README mentions a check, install, or generated output, run the smallest command that verifies the claim when practical.
6. Validate and finish.
   - Run the repo's markdown or prose checks when available.
   - Run a broader check only when the README change changes documented behavior or the repo requires it.
   - Summarize what changed structurally and what was verified.

## Audit Checklist

- The opening paragraph explains the repo without assuming prior context.
- The first actionable path is obvious.
- Setup and daily-use commands are separated.
- Long or rare details link to deeper docs.
- Headings form a usable table of contents.
- Code blocks are not detached from their explanation.
- Lists contain parallel items at the same level of detail.
- The README does not duplicate large chunks of docs that will drift.
- The documented commands exist and still mean what the README says.
