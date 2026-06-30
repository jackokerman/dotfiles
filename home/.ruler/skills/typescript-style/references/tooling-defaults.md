# JS/TS Tooling Defaults

Use this file only when the task includes choosing small reusable libraries for a non-temporary JS/TS tool, helper, or CLI.

## Principles

- Prefer the runtime and standard library first when the native surface is already direct.
- For non-browser tools, helpers, and CLIs, do not overweight bundle-size concerns. Prefer a small vetted dependency when it materially improves semantics, correctness, or readability.
- Add a dependency when it removes repeated boilerplate or common failure handling, not just because it exists.
- Favor community-standard packages with narrow purpose and clear maintenance over custom glue code when both solve the same repeated problem.
- Keep this defaults list short. Add a new default only after the same choice comes up repeatedly.

## HTTP And Request Pacing

- Prefer `ky` for fetch-based HTTP clients when the tool benefits from JSON request helpers, retries, hooks, timeouts, shared defaults, or cleaner error handling.
- Prefer plain `fetch` for tiny one-off requests or when exact low-level request behavior matters more than ergonomics.
- Prefer `p-queue` when provider rate limits or pacing constraints matter. Do not rely on the HTTP client alone to keep requests under strict limits.

## Deterministic Quality Gates

- Add `slop-scan` early for non-temporary Bun/TypeScript CLI tools that agents will edit or invoke repeatedly.
- Make the check blocking by parsing `slop-scan scan . --json` for `summary.findingCount`; print `slop-scan scan . --lint` output on failure so humans and agents get actionable locations.
- Keep the baseline clean and prefer the default rule set with no repo-local config. If a repo needs exceptions, encode them narrowly in `slop-scan.config.json` and capture a follow-up to ratchet them down instead of accepting a permanent noisy warning stream.
- Keep `slop-scan` repo-local by default. Do not add a global wrapper unless at least two repos need the same blocking JSON/lint bridge.

## Duration Parsing And Formatting

- Prefer `ms` for parsing compact duration strings and config-style values such as `5m`, `2h`, or `1d`.
- Prefer `pretty-ms` for human-facing duration output.
- Do not use `ms` when precise user-facing formatting matters; its string output is intentionally compact.
