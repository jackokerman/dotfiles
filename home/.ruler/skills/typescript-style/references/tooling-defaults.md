# JS/TS Tooling Defaults

Use this file only when the task includes choosing small reusable libraries for a non-temporary JS/TS tool, helper, or CLI.

## Principles

- Prefer the runtime and standard library first when the native surface is already direct.
- Add a dependency when it removes repeated boilerplate or common failure handling, not just because it exists.
- Keep this defaults list short. Add a new default only after the same choice comes up repeatedly.

## HTTP And Request Pacing

- Prefer `ky` for fetch-based HTTP clients when the tool benefits from JSON request helpers, retries, hooks, timeouts, shared defaults, or cleaner error handling.
- Prefer plain `fetch` for tiny one-off requests or when exact low-level request behavior matters more than ergonomics.
- Prefer `p-queue` when provider rate limits or pacing constraints matter. Do not rely on the HTTP client alone to keep requests under strict limits.

## Duration Parsing And Formatting

- Prefer `ms` for parsing compact duration strings and config-style values such as `5m`, `2h`, or `1d`.
- Prefer `pretty-ms` for human-facing duration output.
- Do not use `ms` when precise user-facing formatting matters; its string output is intentionally compact.
