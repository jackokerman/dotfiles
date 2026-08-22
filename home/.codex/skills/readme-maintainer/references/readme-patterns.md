# README patterns

Use these patterns selectively. A README should feel native to its project, not generated from a universal template.

## Landing-page quality bar

The opening viewport should establish:

1. **Identity:** what the project is and who it serves.
2. **Value:** the concrete problem it solves or workflow it replaces.
3. **Proof:** a real screenshot, demo, transcript, or small example when the result is visual or otherwise hard to picture.
4. **Action:** the shortest safe path to a successful first use.

Use an existing logo or icon when it aids recognition; do not invent decorative branding. Keep badges to a few live signals that matter to the reader, such as release, build, or compatibility status.

For workflow tools, a strong sequence is: identity and value, real proof, install, first successful use, common workflows, reference, configuration, architecture, then development. Change the order when the reader's actual job demands it.

## Choosing prose, lists, and tables

- Use bullets for unordered peers: prerequisites, installer effects, capabilities, outputs, constraints, and troubleshooting checks.
- Use numbers for a sequence the reader must follow.
- Use prose when one idea explains another, when nuance matters, or when a list would fragment a short argument.
- Use tables for repeated fields such as commands, keybindings, states, configuration, and compatibility.
- Introduce long lists and tables with one sentence that explains how the reader should use them.

Lists become template-like when every section is a list, each item repeats a bold label and dash, or vague benefits replace concrete behavior. Mix structures based on the information rather than applying a visual pattern mechanically.

## Visuals and GFM

- Prefer an actual working state over a decorative hero image.
- Give images useful alt text and keep them near the behavior they demonstrate.
- Use GitHub admonitions sparingly: notes for optional context, important callouts for required prerequisites, and warnings for destructive or costly actions.
- Do not use admonitions for ordinary explanation or stack several together.
- Use collapsible details only for secondary alternatives that would otherwise obscure the default path.

## Installation and safety

Show the recommended installation command first. State what it creates or modifies, whether rerunning it updates safely, and how to reverse it when a supported uninstall path exists. Put version requirements, authentication, destructive effects, refusal states, and preservation guarantees next to the command they protect.

Do not invent an uninstall command or recovery path. If the project deliberately lacks one, document only the safe behavior that exists.

## Progressive disclosure

Keep the README focused on the landing-page job and link to dedicated files instead of duplicating them. When `CONTRIBUTING.md`, `LICENSE`, `CHANGELOG.md`, generated CLI help, architecture docs, or runbooks already exist, summarize only what helps navigation and link to the source of truth.

For command-heavy tools, prefer:

- overview and value;
- install or quick start;
- common workflows;
- a compact command or state reference when it materially helps scanning;
- troubleshooting and safety;
- links to configuration, architecture, and maintainer docs; and
- the smallest contributor check path.

Avoid putting exhaustive flags, hook contracts, generated naming rules, source layout, release machinery, or long architecture explanations ahead of first use.

## Updating an existing README

Do not assume the right edit is additive. Re-read the rendered hierarchy and ask whether the new information changes the audience, primary path, or section order. Consolidate related guidance, delete superseded prose, and move details outward when the landing page becomes denser.

Preserve a recognizable project voice. Avoid generic feature adjectives, excessive emoji, repeated “Overview / Features / Benefits” scaffolding, and badges or sections included only because another README has them.

## Validation

- Confirm the title, description, and first-use path agree with current behavior.
- Run documented commands or compare them with generated help and scripts.
- Check local links and image paths.
- Preserve existing docs-drift checks.
- Inspect the rendered reading order, not only heading output or line count.
- Update adjacent docs and repo steering when setup, commands, configuration, or ownership changed.
