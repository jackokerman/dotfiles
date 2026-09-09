---
name: handy-glossary
description: View and manage Handy's contextual dictation-correction glossary. Use when listing corrections or adding, changing, or removing a contextual misheard-to-replacement entry.
---

# Handy Glossary

Manage the tracked TSV that Handy's post-processing prompt consumes. Do not use Handy's `custom_words` setting; it performs context-insensitive fuzzy replacement.

## Locate the glossary

Use `home/.config/handy/prompts/contextual-glossary.tsv` in the current dotfiles checkout when present. Otherwise, read `${CODEX_HOME:-$HOME/.codex}/skills/.dotty-managed-skills.tsv`, find the `handy-glossary` row's `source_dir`, and resolve its Git root with `git -C <source_dir> rev-parse --show-toplevel`.

This is a public base repository. Do not add private, credential-sensitive, employer-specific, or host-specific vocabulary. Stop and explain that such an entry needs an appropriate local override or later repository in the dotty chain.

## Operations

- With no requested mutation, read the TSV and show the current entries as a compact Markdown table.
- For an addition, capture `misheard`, `replacement`, and a short context that clearly distinguishes valid from invalid uses. Infer context only when the user's wording makes it unambiguous; otherwise ask one concise question.
- Preserve the replacement's exact capitalization and punctuation. Keep every field on one line and reject tabs inside fields.
- Before adding, compare case-insensitively with existing rows. Update the matching row when the user is refining it; allow the same misheard text more than once only when the replacements have clearly distinct contexts.
- For update or removal, resolve exactly one row. Ask before changing anything when the target is ambiguous.

Use `apply_patch` for mutations. Validate that every nonempty row has exactly three tab-separated fields and that the header remains `misheard`, `replacement`, `context`.

After a mutation, follow the owning repository's verification and delivery workflow, including `dotty update` so the rendered prompt reaches Handy. Confirm that Handy remains configured for the managed prompt without displaying unrelated application settings or secrets.
