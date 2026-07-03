---
id: 2026-07-03-build-godspeed-api-tooling
title: Build Godspeed API tooling
state: inbox
createdAt: 2026-07-03T16:10:24.025Z
updatedAt: 2026-07-03T17:30:09.934Z
---

# Build Godspeed API tooling

## Plan

## Objective

Create a reusable TypeScript Godspeed API client and build a small CLI on top of it that gives coding agents structured read and write access to Godspeed.

The first implementation should prioritize the client and CLI. The Raycast extension should be treated as a future consumer and migration target, not as required first-pass delivery, because a partial Raycast implementation already exists elsewhere and is currently lower priority.

The client should cover the full Godspeed API surface that can be verified from official documentation, existing local helper behavior, and direct API observation. It should expose an intuitive typed interface, handle request pacing internally, and avoid requiring callers to understand Godspeed transport quirks.

## Current Context

The dotfiles repo already contains a tracked Godspeed helper at `home/.ruler/skills/godspeed-tasks/scripts/godspeed-tasks.ts`. That helper has confirmed useful API behavior beyond the public task-logging guide, including lists, labels, tasks, bulk lookup, and bulk update transports. It also captures important quirks, such as using `/todo_items/bulk_update` for completion and certain task updates because direct `/tasks/<id>` patches can report success without producing the desired app state.

The implementation should not live in `dotfiles` except for thin bootstrap links, docs, or Codex skill updates. Build the reusable tool in a standalone development repo, then update dotfiles only where needed to make the installed CLI or agent workflow available.

## Recommended Repo And Package Shape

Use a new standalone repo, initially private, with a small TypeScript workspace layout:

- `packages/godspeed-client`: the reusable typed API client.
- `packages/godspeed-cli`: the CLI and agent-facing JSON command surface.
- `docs/`: API inventory notes, usage docs, and publishing/legal decision notes.

Keep room for a future Raycast workspace, such as `apps/raycast-godspeed`, but do not scaffold or implement it in the first pass unless doing so is needed to prove client packaging. The existing work-machine Raycast extension can migrate to the client later once the client contract is stable.

Use Bun workspaces and keep the workspace shape standard through `package.json` so it remains easy to understand and portable if a future package-manager change is needed. Use Vitest as the selected test runner and MSW as the selected HTTP mocking layer for client/CLI integration tests. Add Turborepo only if the initial package scripts become noticeably repetitive or slow. A two-package repo can start with ordinary workspace-aware package scripts; Turborepo becomes useful when build caching or task graph orchestration is actually needed.

Use the existing personal TypeScript repo baseline unless a stronger project-local reason overrides it:

- Bun and TypeScript as the runtime/language baseline,
- Oxlint with `@jackokerman/oxlint-config` for linting,
- the preferred repo-local formatter, confirmed during scaffold rather than assuming Prettier by default,
- `slop-scan` as an agent-facing deterministic quality gate,
- a single `bun run check` command that covers typecheck, lint, format/check, tests, and `slop-scan`.

If `oxformat` or another Oxc formatter package is the current preferred formatter when implementation starts, use it and document the command in the repo. If that default is not yet durable, make formatter selection an explicit scaffold decision and keep it consistent across all workspaces.

Locked initial library choices:

- `ky` for HTTP,
- `p-throttle` for official minute/hour API rate limits,
- `ms` for readable internal duration constants,
- `valibot` for Standard Schema-compatible API shape validation,
- `vitest` for tests,
- `msw` for mocked API integration tests,
- `@stricli/core` for the CLI command framework,
- `tsdown` for client/CLI package builds when emitted JS and declaration files are needed.

Future Raycast library choices, when the extension is migrated or rebuilt:

- `@raycast/api` for the Raycast extension runtime,
- `@raycast/utils` for Raycast-side async state, caching, and common extension helpers where it removes UI boilerplate.

Deferred tooling:

- Add `@changesets/cli` when package publishing becomes active. Do not add release/versioning ceremony before the private local workflow needs it.
- Keep `semantic-release` off the first pass; it is better suited after the public package and release policy are settled.
- Avoid TypeDoc or generated API docs initially. Keep README examples and exported JSDoc accurate first.

Plan to publish at least the client package eventually, but keep the repo/package private until the API inventory and terms checkpoint is complete.

## Package Naming And Distribution

Preferred initial package names:

- `@jackokerman/godspeed-client` for the API client.
- `@jackokerman/godspeed-cli` or a `godspeed`/`godspeed-tasks` bin from the CLI package, depending on npm name availability and confusion risk.

Before public publishing:

- check npm name availability,
- include clear unofficial wording in the README and package metadata,
- avoid implying endorsement by Godspeed or Otto Labs,
- avoid using Godspeed logos or copied brand assets without permission,
- contact Godspeed support if broad use of undocumented endpoints, public npm distribution, or Raycast Store submission could conflict with their intended API use.

Local/private distribution is the default until that review is done. For the Raycast extension, prefer local development or private/team distribution first; public Raycast Store submission is a separate checkpoint.

## API Coverage Strategy

Build an API inventory before finalizing the public client contract.

Official Godspeed API guide coverage, confirmed from `https://godspeedapp.com/guides/api` on 2026-07-03:

- `POST /sessions/sign_in` returns an access token from email/password credentials.
- Users can also copy an API access token from the Godspeed desktop Command Palette; Setapp sign-in requires this path.
- All authenticated API requests use `Authorization: Bearer <token>`.
- `POST /tasks` creates a task. Documented fields include `title`, `list_id`, `location`, `notes`, `due_at`, `timeless_due_at`, `starts_at`, `timeless_starts_at`, `duration_minutes`, `label_names`, `label_ids`, and `metadata`.
- `GET /tasks` returns up to 250 tasks ordered by `updated_at` descending. Documented filters include `status`, `list_id`, `updated_before`, and `updated_after`; pagination uses `updated_before`.
- The API cannot currently return tasks in smart lists.
- `GET /tasks/:task_id` fetches one task.
- `PATCH /tasks/:task_id` updates a task. Documented fields include title/notes/date/duration updates, `is_complete`, `is_cleared`, label add/remove fields, and metadata.
- `DELETE /tasks/:task_id` deletes a task.
- `GET /lists` returns all accessible lists, including shared lists.
- `POST /lists/:list_id/duplicate` duplicates a list and its tasks, with an optional `name`.
- Task `metadata` is officially documented as a string-keyed integration surface and should be represented deliberately in the client types.

Official documented rate limits:

- Listing tasks or lists: do not exceed `10` requests per minute or `200` requests per hour.
- Creating or updating tasks: do not exceed `60` requests per minute or `1,000` requests per hour.
- Exceeding a limit returns `429`.

Inventory steps:

1. Record official API documentation coverage, including auth, endpoints, fields, pagination, metadata behavior, smart-list limitation, and rate limits.
2. Extract endpoint and payload knowledge from the existing `godspeed-tasks.ts` helper, especially behavior that is currently more complete than the official public guide.
3. Use direct API probes with a personal token to verify response shapes, status codes, pagination behavior, rate-limit headers if any, retry behavior, and write semantics.
4. Separate endpoints into these categories:
   - documented and stable,
   - observed and needed,
   - observed but risky or unclear,
   - unsupported or not worth exposing yet.
5. Add tests and fixtures for each verified response shape before exposing it as a public client method.

The client can still aim for full practical coverage, but the first public contract should be honest about what has been verified. Undocumented endpoints should be supported carefully and documented as observed behavior, not as a guaranteed official API.

## Client Design Tenets

Lock the first-pass client interface before implementation. The client should be small, grouped by resource, and easy for both the CLI and future Raycast integration to consume.

Use a factory-created plain object:

```ts
import { createGodspeedClient, signInToGodspeed } from "@jackokerman/godspeed-client";

const client = createGodspeedClient({ token: process.env.GODSPEED_API_TOKEN! });
```

Public constructor/options contract:

```ts
type CreateGodspeedClientOptions = {
  /** Godspeed API bearer token. */
  token: string;
};
```

Do not expose public `baseUrl`, rate-limit, retry, logger, or transport knobs in the first pass. Use MSW for tests and internal dependency injection only if needed. Add public options later only when a real consumer needs them.

Expose top-level helpers:

```ts
async function signInToGodspeed(input: {
  email: string;
  password: string;
  signal?: AbortSignal;
}): Promise<{ accessToken: string }>;
```

The CLI should usually read `GODSPEED_API_TOKEN`; `signInToGodspeed` exists to cover the official API surface and optional human workflows, not as the default agent-auth path.

Expose these resource groups and method names in the client:

```ts
type GodspeedClient = {
  tasks: {
    list(input?: ListTasksInput): Promise<TaskPage>;
    iterate(input?: ListTasksInput): AsyncIterable<GodspeedTask>;
    collect(input?: CollectTasksInput): Promise<GodspeedTask[]>;
    get(input: { taskId: string; signal?: AbortSignal }): Promise<GodspeedTask>;
    getMany(input: { taskIds: string[]; signal?: AbortSignal }): Promise<GodspeedTask[]>;
    create(input: CreateTaskInput): Promise<GodspeedTask>;
    update(input: UpdateTaskInput): Promise<GodspeedTask>;
    complete(input: { taskId: string; completedAt?: string; signal?: AbortSignal }): Promise<GodspeedTask>;
    move(input: { taskId: string; listId: string; signal?: AbortSignal }): Promise<GodspeedTask>;
    delete(input: { taskId: string; signal?: AbortSignal }): Promise<void>;
    bulkUpdate(input: BulkUpdateTasksInput): Promise<GodspeedTask[]>;
  };
  lists: {
    list(input?: { signal?: AbortSignal }): Promise<GodspeedList[]>;
    duplicate(input: { listId: string; name?: string; signal?: AbortSignal }): Promise<GodspeedList>;
  };
  labels: {
    list(input?: { signal?: AbortSignal }): Promise<GodspeedLabel[]>;
    create(input: CreateLabelInput): Promise<GodspeedLabel>;
    ensure(input: EnsureLabelInput): Promise<{ created: boolean; label: GodspeedLabel }>;
  };
  raw: {
    request(input: RawGodspeedRequest): Promise<unknown>;
  };
};
```

Do not expose `client.todoItems` as a first-pass public group. `/todo_items/with_ids` and `/todo_items/bulk_update` are implementation transports behind `tasks.getMany`, `tasks.bulkUpdate`, `tasks.complete`, `tasks.move`, and transport-aware `tasks.update`. Add `todoItems` later only if a real consumer needs to work at that lower level.

Use normalized camelCase public types:

```ts
type GodspeedTask = {
  id: string;
  title: string;
  notes: string;
  listId: string;
  labelIds: string[];
  dueAt: string | null;
  timelessDueAt: string | null;
  startsAt: string | null;
  timelessStartsAt: string | null;
  durationMinutes: number | null;
  completedAt?: string | null;
  clearedAt?: string | null;
  createdAt: string;
  updatedAt: string;
  metadata?: Record<string, unknown>;
};

type GodspeedList = {
  id: string;
  name: string;
  listType: "folder" | "inbox" | "list" | "smart";
  indentLevel: number;
  orderIndex: number;
  smartListQuery: string | null;
  archivedAt: string | null;
};

type GodspeedLabel = {
  id: string;
  name: string;
  colorHexString: string;
  createdAt: string;
  updatedAt: string;
  deletedAt: string | null;
};
```

Use task list pagination types that mirror Godspeed's `updated_before` pagination instead of inventing cursor terminology:

```ts
type ListTasksInput = {
  status?: "incomplete" | "complete" | "all";
  listId?: string;
  updatedBefore?: string;
  updatedAfter?: string;
  signal?: AbortSignal;
};

type TaskPage = {
  tasks: GodspeedTask[];
  nextUpdatedBefore: string | null;
};

type CollectTasksInput = ListTasksInput & {
  maxItems?: number;
};
```

Use semantic task mutation inputs:

```ts
type CreateTaskInput = {
  title: string;
  listId?: string;
  location?: string;
  notes?: string;
  dueAt?: string | null;
  timelessDueAt?: string | null;
  startsAt?: string | null;
  timelessStartsAt?: string | null;
  durationMinutes?: number | null;
  labelIds?: string[];
  labelNames?: string[];
  metadata?: Record<string, unknown>;
  signal?: AbortSignal;
};

type UpdateTaskInput = {
  taskId: string;
  title?: string;
  notes?: string | null;
  listId?: string;
  dueAt?: string | null;
  timelessDueAt?: string | null;
  startsAt?: string | null;
  timelessStartsAt?: string | null;
  durationMinutes?: number | null;
  addLabelIds?: string[];
  removeLabelIds?: string[];
  metadata?: Record<string, unknown>;
  signal?: AbortSignal;
};

type BulkUpdateTasksInput = {
  updates: Array<{
    taskId: string;
    patch: Omit<UpdateTaskInput, "taskId" | "signal">;
  }>;
  signal?: AbortSignal;
};
```

For first-pass public behavior, semantic methods should return the updated/created resource whenever Godspeed returns it. `delete` should return `void` after validating a successful response. Boolean success wrappers can be added in the CLI output layer, not the client.

Raw requests stay intentionally lower-level:

```ts
type RawGodspeedRequest = {
  method?: "DELETE" | "GET" | "PATCH" | "POST";
  path: string;
  query?: Record<string, string | number | boolean | null | undefined>;
  body?: unknown;
  signal?: AbortSignal;
};
```

`client.raw.request` returns `unknown`, uses the same auth, retry, rate-limit classification, and error handling as semantic methods, and should be documented as an escape hatch rather than a preferred API. Internally, semantic methods must parse Valibot schemas before returning typed data.

Use exported error classes:

- `GodspeedApiError` for non-2xx API responses, with `status`, optional `retryAfterMs`, and an `unknown` parsed response body when available.
- `GodspeedValidationError` when a successful response does not match the expected schema.
- `GodspeedRateLimitError` as a specific `GodspeedApiError` subtype for `429` after retry handling is exhausted.

Do not add tRPC for the first implementation. Do not add `ts-rest` or `oRPC` initially. Reconsider only if the API inventory grows enough that a declarative endpoint contract clearly reduces duplication, improves OpenAPI-style documentation, or materially improves generated client ergonomics.

Use typed options objects, named exports, and strict unknown-at-boundary parsing. Add JSDoc for exported contract types, factory helpers, resource groups, and methods.

## Pagination Behavior

Do not add an off-the-shelf pagination dependency in the first implementation. The Godspeed API uses one task-list pagination shape: `GET /tasks` returns up to 250 tasks ordered by `updated_at` descending, and the next page is requested with `updated_before`. A small internal async generator is clearer than a generic iterator or pagination library.

Use these public pagination surfaces:

```ts
await client.tasks.list({ status: "incomplete", listId });

for await (const task of client.tasks.iterate({ status: "incomplete", listId })) {
  // process one task at a time
}

const tasks = await client.tasks.collect({
  status: "incomplete",
  listId,
  maxItems: 500,
});
```

Implementation contract:

- `tasks.list` performs exactly one API request and returns `{ tasks, nextUpdatedBefore }`.
- `tasks.iterate` repeatedly calls `tasks.list`, yields individual tasks, and stops when `nextUpdatedBefore === null`, when an empty page is returned, when the request is aborted, or when a defensive maximum-page guard is reached.
- `tasks.collect` is a convenience wrapper over `iterate`; it should require or default to a conservative `maxItems` and stop once that many tasks have been collected.
- Compute `nextUpdatedBefore` from the last returned task's `updatedAt` only when the page length equals the documented maximum page size of `250`. If fewer than 250 tasks are returned, set `nextUpdatedBefore` to `null`.
- If multiple tasks share the same `updatedAt` at a page boundary and direct API probing shows duplicates or gaps, add a documented de-duplication pass by task ID inside `iterate` before exposing broad collection behavior. Do not guess at this before probing.
- Thread one `AbortSignal` through all page requests.
- Let the existing read limiter govern every page fetch. Do not parallelize task pages because pagination is sequential and the read limit is strict.

Testing contract:

- Unit-test `nextUpdatedBefore` derivation for empty pages, short pages, exact 250-item pages, and missing/invalid `updatedAt` values.
- MSW-test `tasks.iterate` across multiple pages, including stop on short final page and propagation of query params from page to page.
- Test `tasks.collect({ maxItems })` stops without fetching unnecessary extra pages.
- Test abort behavior for a pending multi-page iteration.

## Request, Rate Limit, Queue, And Batch Behavior

Use libraries where they clarify the semantics:

- `ky` for HTTP defaults, JSON helpers, hooks, timeout, retry integration, and consistent error handling.
- Use `p-throttle` as the selected rate-limiting primitive. Godspeed documents fixed minute and hour quotas, and `p-throttle` is current, typed, small, queues calls instead of dropping them, supports `AbortSignal`, exposes `queueSize`, and has a strict mode for interval enforcement.
- Use `ms` for internal duration constants such as limiter intervals and retry/backoff values, so code can say `ms("1 minute")` or `ms("1 hour")` instead of raw millisecond arithmetic. Do not use it for Godspeed task date fields or user-facing date formatting.
- Use `valibot` as the selected schema library for API response and request-shape validation. It supports Standard Schema, has a modern modular API, keeps browser/Raycast bundle impact lower than heavier options, and is a better fit for this client than a larger effect system.
- Use `p-limit` or `p-queue` only if the implementation still needs explicit concurrency limits or queue management that `p-throttle` does not cover cleanly.
- Keep `bottleneck` only as a future fallback for a concrete need such as richer scheduler lifecycle events, priorities, reservoir inspection, or cross-process coordination.

Schema guidance:

- Parse all API responses at the HTTP boundary before returning typed data from resource methods.
- Keep schemas close to the resource group that owns the API shape, then export inferred public types from the package surface when they are part of the client contract.
- Represent official fields and observed undocumented fields deliberately. Avoid broad `record(string, unknown)` escapes except for documented extension surfaces such as task `metadata`.
- Use Standard Schema compatibility as an interop constraint, but write normal Valibot schemas directly inside the client.
- Keep transformations minimal. Prefer validating and normalizing at the API boundary only when the client contract intentionally differs from Godspeed's wire shape.

Model official limits explicitly:

- read/list limiter: `10` requests per minute and `200` requests per hour for listing tasks or lists,
- task-write limiter: `60` requests per minute and `1,000` requests per hour for creating or updating tasks,
- classify delete and non-task write endpoints during API inventory; use the stricter task-write limiter until official behavior is verified,
- handle `429` by honoring `Retry-After` or equivalent response guidance when present, then falling back to bounded exponential backoff.

`p-throttle` implementation guidance:

- Implement a small internal scheduler that composes two throttles per bucket: one minute throttle and one hour throttle.
- Use strict throttling unless tests or direct API behavior show the default windowed behavior is sufficient and materially simpler.
- Thread `AbortSignal` through the throttles and `ky` request so pending scheduled requests can be cancelled.
- Expose no user-tunable rate knobs at first; keep official limits internal and conservative.
- Add focused tests for request classification, throttle composition, cancellation behavior, queue size visibility if surfaced internally, and retry-delay parsing.

The client should own request classification into official limiter buckets, retry of transient `429` and `503` responses, batching helpers for endpoints that support bulk lookup or bulk update, deduping obvious repeated read requests only when a current caller benefits from it, and cancellation through `AbortSignal` where supported by `ky`.

Do not add distributed queueing, persistent offline writes, background sync, or cross-process coordination in the first implementation. The first target is reliable local CLI usage from one user session while keeping the client compatible with a future Raycast migration where reasonable.

## CLI Design

The CLI should be a thin, deterministic wrapper over `godspeed-client` and should be installable as a normal executable on `PATH`.

Installability requirements:

- expose a package `bin`, with the preferred command name settled during package naming,
- support local/private installation before public npm publishing, such as from the development checkout, a private package, or a GitHub dependency,
- keep the install path compatible with dotfiles bootstrap later without requiring agents to know the source repo layout,
- make `godspeed --version` and `godspeed --help` work without an API token,
- fail fast with a clear error when `GODSPEED_API_TOKEN` is missing for authenticated commands.

Agents should use the CLI rather than importing the client directly. A CLI on `PATH` is easier for Codex, Raycast scripts, shell workflows, and other agents to invoke consistently, and it avoids giving every consumer direct access to transport details.

Prioritize agent-safe commands first:

- `godspeed lists --json`
- `godspeed labels --json`
- `godspeed tasks list --list-id <id> --status incomplete --json`
- `godspeed tasks get <task-id> --json`
- `godspeed tasks create --title ... --list-id ... --json`
- `godspeed tasks complete <task-id> --json`
- `godspeed tasks update <task-id> ... --json`
- `godspeed tasks move <task-id> --list-id ... --json`
- `godspeed labels ensure --name ... --json`

Keep output structured by default for commands intended for agents. Human-friendly table output can be added later if it becomes useful, but it should not complicate the initial command contract.

Ship agent-facing context with the CLI repo:

- a `docs/agent-usage.md` guide with authentication, safe read commands, safe write commands, preview/apply expectations, common examples, exit-code behavior, and JSON output conventions,
- command help text that is accurate enough for an agent to discover basic usage from `--help`,
- JSON examples in the README or agent guide for the main read/write flows,
- notes on destructive or subjective operations so agents know when to preview or ask for confirmation.

Authentication should be CLI-owned, not client-owned:

- read `GODSPEED_API_TOKEN`,
- support `--token` only if there is a concrete need,
- support env-file loading through the invocation environment rather than custom shell sourcing,
- never print tokens.

Bulk, heuristic, or subjective operations should have an explicit preview/apply split.

## Raycast Extension Design

Defer Raycast implementation from the first pass.

The first implementation should keep the client usable from a future Raycast extension by avoiding Node-only assumptions in the core client where reasonable, keeping package exports clean, and documenting browser/Raycast-relevant authentication and bundling constraints as they are discovered.

When the Raycast extension is migrated or rebuilt later, build it as a separate app workspace consuming `godspeed-client`. The existing work-machine extension can serve as the migration source instead of recreating everything from scratch.

Use Raycast preferences or secure storage for the API token. Keep any personal list mappings local to Raycast preferences or runtime discovery; do not bake private taxonomy into the public repo.

## Inspiration And Prior Art

Prior-art investigation completed on 2026-07-03 using published packages and local package tarballs:

- `@doist/todoist-sdk@10.5.1`: official Todoist SDK. It exposes a large class with flat task/project methods such as `getTasks`, `addTask`, `updateTask`, and `closeTask`; it uses typed options objects and paginated response objects with `nextCursor`. Useful for task-domain method naming and typed request/response shapes, but too flat and class-heavy for this client.
- `@notionhq/client@5.22.0`: official Notion SDK. It exposes grouped resource methods such as `notion.pages.create`, `notion.databases.retrieve`, and `notion.users.list`; all endpoint parameters go into one object; it ships `iteratePaginatedAPI` and `collectPaginatedAPI`; it includes `notion.request()` for unsupported endpoints. This is the strongest shape inspiration.
- `@lionralfs/discogs-client@4.1.4`: Discogs client. It exposes resource groups through methods like `client.database()` and `client.user().collection()`, returns rate-limit metadata, documents pagination, and has lower-level request helpers. Useful for grouped API shape and rate-limit visibility, but its class/setter style and callback internals should not be copied.
- `stripe@22.3.0`: Stripe's Node client. It uses resource-group methods, explicit auto-pagination helpers, rich errors, and `rawRequest()` for undocumented/private-beta endpoints. Useful for raw escape hatch and pagination ergonomics, but too generated/heavy for this project.
- Existing `home/.ruler/skills/godspeed-tasks/scripts/godspeed-tasks.ts`: confirmed Godspeed-specific behavior, including list/label discovery, task CRUD, `/todo_items/with_ids`, `/todo_items/bulk_update`, transport selection for list/completion updates, retry delay parsing, and current CLI workflows that must be preserved.

Locked takeaways:

- Use grouped resources like Notion/Stripe, not a large flat Todoist-style class.
- Use a factory-created plain object, not a public class with mutable setters.
- Use typed options objects for all multi-field operations.
- Return normalized camelCase public types from semantic methods; keep Godspeed snake_case wire shape inside schemas and raw helpers.
- Provide explicit pagination helpers instead of hiding unbounded pagination behind ordinary list calls.
- Provide a raw request escape hatch for verified-but-not-promoted or newly observed endpoints, returning `unknown` unless the implementation validates the response internally.
- Keep auth token handling in the client constructor, while sign-in/token acquisition remains a separate helper so CLI auth policy can stay CLI-owned.
- Hide Godspeed transport quirks behind semantic methods; callers should not know whether an update used `/tasks/:id` or `/todo_items/bulk_update`.

## Legal, Permission, And Privacy Checkpoint

Before publishing publicly or submitting to the Raycast Store:

- review Godspeed's current API guide, EULA, privacy policy, and any developer/API terms that exist,
- confirm whether the documented API is intended only for task logging or for broader task-management clients,
- ask Godspeed support for guidance if broad client coverage depends on undocumented endpoints,
- avoid trademark confusion by making the project clearly unofficial,
- avoid publishing copied docs, screenshots, icons, or brand assets without permission,
- make the package and extension privacy posture explicit: user token stays local, requests go only to Godspeed, no telemetry unless deliberately added later.

Keep the implementation private until this checkpoint is resolved. A private package or GitHub dependency is enough for the CLI/Raycast workflows while the permission question is open.

## Implementation Stages

1. Create the standalone repo and workspace skeleton with TypeScript, Bun, Oxlint, `@jackokerman/oxlint-config`, the selected formatter, `slop-scan`, Vitest, MSW test setup, and minimal package docs.
2. Build the API inventory from official docs, the existing helper, and direct probes. Record verified endpoint contracts and unknowns in `docs/`.
3. Implement the client core: `ky` instance, auth injection, error types, `p-throttle` read/write schedulers, Valibot response parsing, retry/backoff, pagination helpers, and raw request helper.
4. Implement verified resource groups for lists, labels, tasks, todo-item bulk lookup/update, smart-list helpers, and semantic methods that hide known transport quirks.
5. Port the existing dotfiles Godspeed helper behavior onto the new client and keep tests covering current workflows.
6. Build the installable CLI with stable JSON output, useful `--help`, `--version`, token-missing errors, and preview/apply boundaries for risky writes.
7. Add agent-facing CLI docs in the standalone repo, especially `docs/agent-usage.md`, so agents can discover safe read/write workflows without reading implementation code.
8. Prove local/private installation works from a clean shell with the command on `PATH` and `GODSPEED_API_TOKEN` supplied by the environment.
9. Migrate the dotfiles Godspeed skill/bootstrap path to use the installed CLI only after the CLI covers the current helper workflows. Keep the old helper available until parity is verified, then remove or reduce it to thin compatibility glue in the same dotfiles change.
10. Run the legal/privacy/package checkpoint and decide whether to keep private, publish only the client package, or publish client plus CLI.
11. If public publishing is approved, add release automation, npm package metadata, consumer-focused READMEs, and provenance/trusted publishing after the first authenticated publish.
12. Later, migrate or rebuild the Raycast extension as a separate app workspace consuming the client. Treat this as a follow-up phase, not part of the first implementation contract.

## Verification

Use a layered test strategy:

- Unit tests for pure logic: request classification, `p-throttle` scheduler construction, retry delay parsing, pagination next-token derivation, batch planning, list/task normalization, and semantic transport selection.
- Valibot schema tests using static fixtures copied from official docs and direct API probes. These should cover successful parsing, missing required fields, nullable fields, documented optional fields, and observed undocumented fields that the client deliberately supports.
- MSW-backed client integration tests for the main HTTP paths, including multi-page `tasks.iterate` and `tasks.collect` behavior.
- CLI JSON contract tests for agent-facing commands. Prefer running the CLI against the same MSW handlers instead of stubbing the client, so auth headers, URLs, query params, request bodies, validation, and output shape are exercised together.
- CLI installability checks that prove the package bin can run from a clean shell, `--help` and `--version` do not need a token, authenticated commands read `GODSPEED_API_TOKEN`, and missing-token errors are clear.
- Agent documentation checks that keep the README and `docs/agent-usage.md` aligned with command names, JSON output, preview/apply behavior, and install instructions.
- Dotfiles parity checks before replacing the existing Godspeed helper: confirm the installed CLI covers current list discovery, inbox/task reads, task creation/update/completion, labels, and any bulk update behavior used by the skill.
- `bun run check` in the standalone repo.
- Dotfiles check only when dotfiles integration changes.

MSW scope:

- Use MSW for mostly end-to-end tests of the client and CLI against representative Godspeed API behavior.
- Keep handlers explicit and local to test suites or a small `test/msw/` helper. Do not build a full fake Godspeed server.
- Assert the client sends the expected `Authorization` header, query params, and JSON body for core endpoints.
- Cover error cases: `401`, `404`, validation failure from malformed success payloads, `429` with `Retry-After`, and transient `503` retry behavior.
- Avoid testing the full wall-clock behavior of official rate limits through MSW. Test limiter classification and retry-delay logic separately with fast unit tests.

Avoid live destructive API tests by default. For live write verification, use an explicitly named scratch list or test task prefix and clean it up through the API. Gate live tests behind an explicit environment variable and never run them in the default check.

Do not require Raycast development checks for the first implementation. Add Raycast-specific smoke tests and manual verification in the later Raycast migration phase.

## Non-Goals For The First Implementation

- Do not implement or migrate the Raycast extension in the first pass.
- Do not implement a full offline sync engine.
- Do not mirror Godspeed's local app database.
- Do not reverse engineer the desktop app bundle unless direct API observation and docs are insufficient for a required workflow.
- Do not create a public Raycast Store submission before the API/terms checkpoint and a separate Raycast migration phase.
- Do not add shared hosted infrastructure.
- Do not encode personal label taxonomies or smart-list rules in a public repo.

## Open Decisions

Resolve before scaffold or first CLI implementation:

- Confirm the standalone repo name. Working name: `godspeed-tools` or `godspeed-js`.
- Decide whether npm packages should be private scoped packages first or unpublished workspace packages consumed locally.
- Decide the exact CLI JSON envelope before implementation. Prefer a stable shape such as `{ ok: true, data }` and `{ ok: false, error }` for agent-facing commands unless that proves unnecessarily noisy.
- Decide whether the first CLI should optimize only for agents or include human-friendly output from day one. Current recommendation: agent-first JSON only, with human-friendly output deferred.
- Decide whether CLI commands should expose explicit `--dry-run`/`--apply` flags for all writes or only for bulk/heuristic/subjective operations. Current recommendation: require preview/apply only for bulk, heuristic, or subjective operations; keep direct single-task writes simple.

Resolve during API inventory/probing:

- Confirm whether `DELETE /tasks/:task_id`, `POST /lists/:list_id/duplicate`, and any observed undocumented write endpoints should use the task-write limiter or a stricter limiter.
- Confirm date/time semantics: which fields require ISO timestamps, which accept date-only values, how timeless fields behave, and whether the client should validate formats before sending requests.
- Decide whether `metadata` values should be limited to JSON-serializable primitives/objects in the public type instead of `Record<string, unknown>`.
- Decide how much undocumented API coverage is acceptable before contacting Godspeed support.
- Decide whether to add a documented API drift check, such as fixture refresh instructions or a live read-only smoke test gated by `GODSPEED_API_TOKEN`, so the client can detect upstream response changes without destructive calls.

Resolve during dotfiles migration:

- Decide the dotfiles migration rollback strategy: keep the old helper until CLI parity is verified, then either remove it in the same change or leave a very thin fallback for one release cycle. Current recommendation: remove or reduce it to thin compatibility glue in the same dotfiles change once parity passes.
