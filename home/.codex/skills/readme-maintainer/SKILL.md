---
name: readme-maintainer
description: Use when writing, restructuring, auditing, or updating README and repository landing pages, including setup, usage, contributor guidance, linked docs, and documentation-drift checks.
---

# README Maintainer

Treat the README as the repository landing page, not the complete manual. Work from repository truth and make the first useful path obvious.

## Core contract

- Identify the primary audience and job: first install, daily use, contribution, operations, library consumption, or repository navigation.
- For material updates, reassess the hierarchy instead of appending another section. Remove stale, duplicated, or newly peripheral detail.
- Make the first screen answer: What is this? Why would I use it or what does it replace? What does success look like? What should I do next?
- Lead with a one-sentence identity and a short, concrete value explanation. Show real proof near the top when the UI or workflow is the product.
- Keep the paved path in the README. Move exhaustive options, internals, rare troubleshooting, and maintainer procedures into linked docs when possible.

## Scanability without template texture

- Use bullets for peer items readers compare or scan: prerequisites, features, side effects, outcomes, options, and short steps.
- Use prose for rationale, relationships, caveats, and transitions. Use numbered lists only when order matters.
- Use tables for dense mappings or reference, not narrative.
- Keep list items parallel and concrete. Avoid emoji-decorated feature soup, repetitive bold-label lists, badge walls, and turning every paragraph into bullets.
- Prefer specific behavior, constraints, and tradeoffs over generic claims such as “powerful,” “seamless,” or “comprehensive.”

## Workflow

1. Inspect `README.md`, repo instructions, manifests, scripts, CLI help, tests, examples, and nearby docs. Find any checks that keep documented commands or flags current.
2. Choose the smallest structure that serves the primary reader. Preserve stronger local conventions and existing useful voice.
3. Draft top-down: identity and value, proof when useful, install or quick start, first success, common workflows, then reference and internals.
4. Put commands beside their purpose. Put prerequisites, side effects, refusal behavior, and reversibility beside the action they govern.
5. Verify commands and links against their sources of truth, run the smallest relevant docs or repo check, and update adjacent docs or steering when the workflow changed.

Read `references/readme-patterns.md` when creating or materially restructuring a README, when the project is command-heavy or visual, or when deciding how to use screenshots, badges, GFM admonitions, tables, deeper docs, or maintainer sections.
