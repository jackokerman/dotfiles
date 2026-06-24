# README Patterns

Load this reference when a README is command-heavy, a repo already has substantial docs, or a rewrite risks becoming a generic template.

## Source Patterns

- GitHub README guidance: a README should tell visitors what the project does, why it is useful, how to get started, where to get help, and who maintains it.
- Google README guidance: a README is a short summary for people browsing code, especially first-time users.
- Diataxis: keep tutorials, how-to guides, reference, and explanation distinct. The README can route to all four, but should not flatten all four into one long page.
- Vale and markdownlint: use them for style and mechanics when configured. They do not decide audience, hierarchy, command truth, or README-vs-docs boundaries.
- README generators and templates: use them for section vocabulary and bootstrapping only. Do not let them overwrite local workflow shape.

## Command-Heavy CLI Structure

Use this structure as a starting point, then adapt to the repo:

- Overview: one short paragraph with the audience and job.
- Install or quick start: the shortest path to a working command.
- Common tasks: task-oriented examples users run repeatedly.
- Command reference: exhaustive flags, subcommands, config, hooks, or environment variables.
- Troubleshooting: common failures and the smallest checks that identify them.
- Maintainer workflow: release, smoke, generated files, or development commands.
- Deeper docs: architecture, uncommon operations, and long explanations.

Keep the first half of the README useful to new or daily users. Put rare maintainer workflows, exhaustive hook contracts, and long configuration explanation later or in `docs/`.

## Command Explanation Patterns

- Prefer short command blocks with nearby prose that says why or when to run them.
- Split commands by workflow when a single block needs many trailing comments.
- Use a table when readers compare flags, environment variables, hooks, config keys, or command meanings.
- Use a quick-reference block only when the section is explicitly for scanning commands.
- Keep generated help and README option lists in sync through existing tests or by adding a narrow drift check when the repo already has that pattern.

## Large CLI Stress Case

A CLI README can become dense when it mixes install, source fallback, completion troubleshooting, launch flow, options, machine-readable output, configuration, hooks, and development in one page.

For a repo like that:

- Keep install, quick start, common usage examples, and health-check commands near the top.
- Treat exhaustive options, config precedence, hooks, generated naming, and maintainer smoke tests as reference material.
- Preserve local drift checks such as a test that asserts README coverage for CLI flags or generated completions.
- Inspect rendered structure, not just `rg '^#'`, because headings inside shell examples are code comments rather than Markdown sections.
