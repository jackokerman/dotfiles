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
- Prefer `p-throttle` for simple fixed-window API quotas such as `60/minute` plus `1,000/hour`, especially when the provider publishes explicit limits.
- Prefer `p-queue` or `p-limit` when the problem is concurrency, ordering, backpressure, or an explicit work queue rather than fixed-window throttling.
- Do not rely on the HTTP client alone to keep requests under strict provider limits.

## General Utilities

- Prefer built-in JavaScript and TypeScript features when they are direct and readable.
- Prefer `es-toolkit` when a non-temporary tool needs repeated collection, object, predicate, string, promise, or function utilities that would otherwise become local helper boilerplate.
- Prefer focused imports from `es-toolkit` or its category exports. Avoid `es-toolkit/compat` unless migrating existing Lodash-shaped code.

## Runtime Data Boundaries

- Prefer a schema library at API, config, storage, and CLI input boundaries when the data is external or untrusted.
- Consider `arktype` first for new owned TypeScript tools when a TypeScript-like runtime schema library is useful and the surrounding project has no stronger existing pattern.
- Do not churn existing `valibot`, `zod`, or other schema-library usage merely because `arktype` is the preferred default for new owned tools.
- Keep schemas close to the resource or module that owns the boundary, and export inferred types only when they are part of the public contract.
- Do not add runtime schemas for purely internal objects that TypeScript already owns end-to-end.

## CLIs, Packages, And Builds

- Prefer Bun workspaces for small owned TypeScript tool repos and monorepos unless a surrounding project already standardizes on another package manager.
- Prefer `@stricli/core` when a CLI has multiple commands, typed options, or durable agent-facing contracts. Use a smaller parser or native argument handling for tiny one-off scripts.
- Prefer `tsdown` when a package needs emitted JavaScript, declaration files, or publishable artifacts. Skip a build step for Bun-only scripts that can run TypeScript directly.
- Defer Turborepo until repeated workspace scripts are slow or coordination is painful enough to justify task orchestration and caching.
- Defer `@changesets/cli` until package publishing or versioned release notes are active. Do not add release machinery before the release policy is known.

## Testing Networked Tools

- Prefer `vitest` for non-temporary JS/TS package tests.
- Prefer `msw` for API client and CLI integration tests when mocking the HTTP boundary is more valuable than stubbing the client internals.
- Keep pure logic, schema fixture, and command-shape tests separate from mocked-network tests so failures point at the right layer.
- Gate live API tests behind explicit environment variables and scratch resources; do not make destructive external calls part of the default test suite.

## Raycast Extensions

- Use the official `@raycast/api` package for Raycast extensions.
- Consider `@raycast/utils` for async state, caching, forms, and common extension ergonomics before writing local wrappers.
- Check Raycast's official docs before changing metadata, output behavior, authentication, or packaging assumptions.

## Deterministic Quality Gates

- Add `slop-scan` early for non-temporary Bun/TypeScript CLI tools that agents will edit or invoke repeatedly.
- Make the check blocking by parsing `slop-scan scan . --json` for `summary.findingCount`; print `slop-scan scan . --lint` output on failure so humans and agents get actionable locations.
- Keep the baseline clean and prefer the default rule set with no repo-local config. If a repo needs exceptions, encode them narrowly in `slop-scan.config.json` and capture a follow-up to ratchet them down instead of accepting a permanent noisy warning stream.
- Keep `slop-scan` repo-local by default. Do not add a global wrapper unless at least two repos need the same blocking JSON/lint bridge.

## Duration Parsing And Formatting

- Prefer `ms` for parsing compact duration strings and config-style values such as `5m`, `2h`, or `1d`.
- Prefer `pretty-ms` for human-facing duration output.
- Do not use `ms` when precise user-facing formatting matters; its string output is intentionally compact.
