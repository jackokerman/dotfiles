---
id: 2026-07-03-build-godspeed-api-tooling
title: Build Godspeed API tooling
state: ready-to-ship
createdAt: 2026-07-03T16:10:24.025Z
updatedAt: 2026-07-07T02:55:28.388Z
---

# Build Godspeed API tooling

## Plan

## Objective

Create `GodspeedJS`: a private standalone TypeScript repo that provides a reusable Godspeed API client plus an installable CLI for coding agents and shell workflows.

The first implementation should replace the current hand-rolled Godspeed helper in dotfiles after CLI parity is proven. It should not publish packages publicly or migrate Raycast in the first pass.

## Repo And Distribution

Use private GitHub repo `godspeed-js`, checked out at `~/src/godspeed-js`. Use `GodspeedJS` as the display/project name in docs.

Keep implementation code out of dotfiles. Dotfiles may get only bootstrap, install, docs, or skill changes needed to consume the installed CLI. Do not add `godspeed-js` to `.dotty/dev-checkouts.tsv` unless dotfiles later needs to manage that checkout as bootstrap state.

Use a Bun TypeScript workspace:

- `packages/godspeed-client`: typed API client.
- `packages/godspeed-cli`: CLI and agent-facing JSON command surface.
- `docs/`: API inventory, CLI usage, and publishing/legal notes.

Keep packages unpublished initially. Commit and push the private repo to GitHub once the standalone tool passes checks. Public npm publishing, release automation, and Raycast Store submission are follow-up checkpoints.

Initial package and command names:

- `@jackokerman/godspeed-client`
- `@jackokerman/godspeed-cli`
- preferred executable: `godspeed`, unless local testing shows a conflict or confusion risk; fallback: `godspeed-tasks`

Use the existing personal TypeScript baseline unless implementation finds a concrete reason to differ:

- Bun and TypeScript
- Oxlint with `@jackokerman/oxlint-config`
- the current preferred repo formatter, confirmed during scaffold
- `slop-scan`
- Vitest and MSW
- one `bun run check` covering typecheck, lint, format/check, tests, and `slop-scan`

Selected first-pass libraries:

- `ky` for HTTP
- `p-throttle` for minute/hour request pacing
- `ms` for internal duration constants
- `valibot` for response/request validation
- `vitest` for tests
- `msw` for mocked API integration tests
- `@stricli/core` for CLI commands
- `tsdown` when emitted JS and declarations are needed

Do not add Turborepo, Changesets, semantic-release, TypeDoc, tRPC, `ts-rest`, or `oRPC` in the first pass unless implementation exposes a concrete need.

## Existing Context

Dotfiles currently has `home/.ruler/skills/godspeed-tasks/scripts/godspeed-tasks.ts`. Preserve and replace its real behavior, including:

- list, label, and task discovery
- task creation, update, move, and completion
- bulk lookup and bulk update transports
- retry delay parsing
- the known Godspeed quirk where `/todo_items/bulk_update` is needed for completion and some updates because direct `/tasks/<id>` patches can report success without producing the desired app state

The CLI should become the durable agent boundary. Agents should not import the client directly for normal task workflows.

## API Inventory Contract

Build `docs/api-inventory.md` before finalizing public client behavior. Use official docs, the existing dotfiles helper, and direct API probes with `GODSPEED_API_TOKEN`.

Official Godspeed API guide coverage confirmed on 2026-07-03:

- `POST /sessions/sign_in`
- bearer-token auth via `Authorization: Bearer <token>`
- `POST /tasks`
- `GET /tasks` with `status`, `list_id`, `updated_before`, `updated_after`, max 250 tasks, and `updated_before` pagination
- `GET /tasks/:task_id`
- `PATCH /tasks/:task_id`
- `DELETE /tasks/:task_id`
- `GET /lists`
- `POST /lists/:list_id/duplicate`
- task `metadata` as a documented integration field
- smart-list tasks are not currently returned by the documented task API
- documented limits: list/read calls at `10/minute` and `200/hour`; create/update calls at `60/minute` and `1,000/hour`; excess returns `429`

Inventory should classify endpoints as:

- documented and stable
- observed and needed
- observed but risky or unclear
- unsupported or not worth exposing yet

Undocumented transports can be used when they are required for parity, but document them as observed behavior. Do not publish publicly until the legal/API-use checkpoint is complete.

## Client Contract

Export a factory-created plain object, not a public class:

```ts
import { createGodspeedClient, signInToGodspeed } from "@jackokerman/godspeed-client";

const client = createGodspeedClient({ token: process.env.GODSPEED_API_TOKEN! });
```

First public options contract:

```ts
type CreateGodspeedClientOptions = {
  /** Godspeed API bearer token. */
  token: string;
};
```

Do not expose public `baseUrl`, retry, logger, transport, or rate-limit knobs initially. Use internal dependency injection only for tests if needed.

Expose `signInToGodspeed` because it is official API surface, but the CLI should use `GODSPEED_API_TOKEN` as its first-pass auth path.

Client resources:

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

Do not expose `client.todoItems` initially. Hide `/todo_items/with_ids` and `/todo_items/bulk_update` behind semantic task methods.

Use normalized camelCase public types. Keep Godspeed snake_case wire shapes inside schemas and request mappers. Parse successful semantic responses with Valibot before returning typed data.

Errors:

- `GodspeedApiError` for non-2xx responses, including `status`, optional `retryAfterMs`, and parsed response body when available
- `GodspeedRateLimitError` for exhausted `429` handling
- `GodspeedValidationError` for successful responses that fail schemas

Pagination:

- `tasks.list` performs one request and returns `{ tasks, nextUpdatedBefore }`.
- `tasks.iterate` sequentially follows `updated_before`, yields tasks, and stops on `nextUpdatedBefore === null`, empty page, abort, or a defensive max-page guard.
- `tasks.collect` wraps `iterate` and stops at a conservative `maxItems`.
- Compute `nextUpdatedBefore` from the last task `updatedAt` only when the page length is exactly 250. Short pages return `null`.
- If probing shows duplicate/gap risk for equal `updatedAt` page boundaries, add documented de-duping by task ID inside `iterate`.

Rate limiting and retries:

- compose `p-throttle` minute and hour throttles per bucket
- use read/list limits for task/list reads
- use task-write limits for create/update and stricter write-like endpoints until probed
- honor `Retry-After` or equivalent guidance for `429`, then use bounded exponential backoff
- retry transient `503` responses conservatively
- thread `AbortSignal` through throttles and `ky`
- expose no public rate-limit knobs initially

## CLI Contract

The CLI is a thin deterministic wrapper over `godspeed-client` and should be installable as a normal executable on `PATH`.

Requirements:

- `godspeed --help` and `godspeed --version` work without an API token
- authenticated commands read `GODSPEED_API_TOKEN`
- missing-token failures are clear and never print secrets
- no `--token` flag in the first pass unless implementation finds a concrete need
- env-file loading is left to the invocation environment
- JSON is the first-class output contract; defer human table output

Initial commands:

- `godspeed lists --json`
- `godspeed labels --json`
- `godspeed labels ensure --name ... --json`
- `godspeed tasks list --list-id <id> --status incomplete --json`
- `godspeed tasks get <task-id> --json`
- `godspeed tasks create --title ... --list-id ... --json`
- `godspeed tasks update <task-id> ... --json`
- `godspeed tasks move <task-id> --list-id ... --json`
- `godspeed tasks complete <task-id> --json`

JSON envelope:

```json
{ "ok": true, "data": {} }
```

```json
{ "ok": false, "error": { "code": "missing_token", "message": "GODSPEED_API_TOKEN is required for this command." } }
```

Command-specific `data` should stay close to client return values. Errors should include stable `code`, human `message`, and safe details such as HTTP status when useful.

Mutation safety:

- exact single-task writes may execute directly when task IDs and fields are supplied
- bulk writes, heuristic writes, subjective categorization, inferred list/label changes, and commands operating on search/list results must support preview/apply before mutation
- do not add `--dry-run`/`--apply` to every write command just for ceremony

Add `docs/agent-usage.md` with auth, safe reads, safe writes, preview/apply expectations, JSON conventions, examples, and exit-code behavior.

## Dotfiles Migration Contract

After the standalone CLI passes checks and covers current helper workflows, update dotfiles to consume the installed CLI.

Parity must cover:

- list discovery
- label discovery and ensure/create behavior
- inbox/task reads
- task creation
- task update and move
- task completion
- bulk lookup/update behavior used by the current skill

Keep the old helper until parity is verified. Then remove it or reduce it to thin compatibility glue in the same dotfiles change. Prefer removal if the CLI fully covers the skill workflow.

For dotfiles changes, follow repo workflow: run the appropriate check, commit with a conventional commit, push `main`, and run `dotty update` if live config needs to reflect the repo state.

## Verification

Standalone `godspeed-js` verification:

- unit tests for request classification, scheduler construction, retry delay parsing, pagination derivation, batch planning, normalization, and transport selection
- Valibot schema tests using fixtures from official docs and direct probes
- MSW-backed client tests for auth headers, URLs, query params, request bodies, success paths, and error paths
- MSW-backed CLI contract tests for JSON output and exit behavior
- pagination tests for exact 250-item pages, short pages, multi-page iteration, `collect({ maxItems })`, and abort behavior
- error tests for `401`, `404`, malformed success payloads, `429` with retry guidance, and transient `503`
- installability checks proving the bin runs from a clean shell, `--help`/`--version` do not need a token, and authenticated commands read `GODSPEED_API_TOKEN`
- docs checks keeping README and `docs/agent-usage.md` aligned with command names and JSON output
- `bun run check`

Avoid live destructive API tests by default. Gate live tests behind explicit env vars. For live write verification, use a scratch list or test-task prefix and clean it up through the API.

Dotfiles verification:

- parity check against current `godspeed-tasks` skill workflows before replacing the helper
- `./scripts/check --quiet` for routine dotfiles integration
- stronger dotfiles checks only if helper/bootstrap/check-runner behavior warrants them

## Legal And Publishing Checkpoint

Before public npm publishing or Raycast Store submission:

- review current Godspeed API docs, EULA, privacy policy, and developer/API terms if present
- confirm whether broad task-management clients are acceptable API use
- ask Godspeed support if undocumented endpoints are required for public behavior
- make the project clearly unofficial
- avoid copied logos, screenshots, docs, or brand assets without permission
- document privacy posture: token stays local, requests go only to Godspeed, no telemetry unless deliberately added later

This checkpoint does not block the private end-to-end local workflow.

## Non-Goals

- no public publishing in the first pass
- no Raycast implementation or migration in the first pass
- no full offline sync engine
- no local app database mirror
- no desktop app reverse engineering unless docs, helper behavior, and direct API observation are insufficient for a required workflow
- no shared hosted infrastructure
- no personal label taxonomy or smart-list rules in a public repo

## Implementation Stages

1. Create private GitHub repo `godspeed-js`, clone it to `~/src/godspeed-js`, and scaffold the workspace.
2. Inventory official, observed, and required API behavior in `docs/api-inventory.md`.
3. Implement client core: HTTP, auth, schemas, errors, rate limiting, retries, pagination, and raw request.
4. Implement lists, labels, tasks, and semantic task methods that hide todo-item transport quirks.
5. Implement the CLI with the selected commands, JSON envelope, help/version behavior, token errors, and mutation safety rules.
6. Add README and `docs/agent-usage.md`.
7. Port/cover existing dotfiles helper workflows in tests.
8. Prove local/private install from a clean shell.
9. Run `bun run check`, commit, and push the private `godspeed-js` repo.
10. Migrate dotfiles skill/bootstrap to the installed CLI after parity passes.
11. Run dotfiles verification, commit, push `main`, and run `dotty update` if needed.
12. Leave publishing and Raycast migration as follow-up checkpoints.

## Ready Boundary

This plan is ready when an implementation agent can build the private end-to-end workflow without another planning pass:

- private `godspeed-js` repo at `~/src/godspeed-js`
- checked client, CLI, docs, and local install proof
- CLI parity with the current dotfiles helper
- dotfiles migration replacing the helper only after parity is verified
- private repo committed and pushed
- dotfiles integration committed and pushed if changed

## Remaining Decisions During Implementation

Resolve during scaffold:

- confirm the repo formatter
- confirm `godspeed` does not conflict as a local executable name

Resolve during API inventory:

- limiter bucket for `DELETE /tasks/:task_id`, `POST /lists/:list_id/duplicate`, and observed undocumented write endpoints
- date/time field semantics and whether the client validates formats before sending
- whether `metadata` should be typed more narrowly than `Record<string, unknown>`
- how much undocumented endpoint coverage is acceptable before contacting Godspeed support
- whether to add a read-only live API drift check gated by `GODSPEED_API_TOKEN`

Resolve during dotfiles migration:

- remove the old helper outright or leave thin compatibility glue for one release cycle; current recommendation is removal if parity is complete

## Agent handoff

Fresh persisted state was `ready-to-implement`, but the prior handoff was stale: both `/Users/jackokerman/src/godspeed-js` and `/Users/jackokerman/dotfiles` were already clean on `main` with no ahead commits, and recent history shows the earlier GodspeedJS implementation and consolidation follow-up were committed and pushed.

Next honest implementation step completed in `/Users/jackokerman/src/godspeed-js`: fixed local install drift after the compatibility `godspeed-tasks` bin was removed. `bun run install:local` now runs `scripts/install-local.ts`, which wraps the existing `bun link` for `packages/godspeed-cli` and removes only the obsolete `godspeed-tasks` symlink from Bun's install bin directory when it points at the removed `@jackokerman/godspeed-cli/src/godspeed-tasks.ts` entrypoint. This keeps `dotty update` aligned with current docs: install/link the `godspeed` CLI only, while the tracked dotfiles skill uses `godspeed gtd ...` commands.

Verification passed:

- `/Users/jackokerman/src/godspeed-js`: `bun run install:local` succeeded and removed the stale local `godspeed-tasks` link.
- `/Users/jackokerman/src/godspeed-js`: `zsh -lc 'command -v godspeed && ! command -v godspeed-tasks && godspeed --version && godspeed --help >/dev/null && godspeed gtd --help >/dev/null'` passed and printed the `godspeed` path plus version `0.1.0`.
- `/Users/jackokerman/src/godspeed-js`: `bun run check` passed.
- `/Users/jackokerman/dotfiles`: `./scripts/check --quiet` passed before the install cleanup change; no dotfiles implementation files changed after that.

Current review gate:

- `/Users/jackokerman/src/godspeed-js` has uncommitted changes in `package.json` and new `scripts/install-local.ts`.
- `/Users/jackokerman/dotfiles` has only this Jackie Plan checkpoint update after checkpointing.
- Do not commit, push, mark `ready-to-ship`, mark `complete`, or archive until the user reviews and explicitly approves follow-through.

### Process notes from this session

The persisted handoff can lag behind reality when implementation work is committed in later sessions without lifecycle advancement. This session corrected the checkpoint with repo status and recent history before adding new implementation work.

The stale `godspeed-tasks` symlink demonstrated a concrete cleanup gap from removing a Bun package bin. The fix belongs in `godspeed-js` `install:local`, because dotfiles delegates linking to that standalone repo and should not know about removed package internals.

## Process notes

The root dotfiles `package.json` cannot be removed entirely because it still supports other repo TypeScript scripts such as Karabiner and Codex sync. The integration removed only the Godspeed-specific dependency and test lane from dotfiles.

The moved `godspeed-tasks` compatibility helper is intentionally marked as legacy with local lint/type waivers in `godspeed-js`. It preserves behavior for the dotfiles skill while the lower-level `godspeed` CLI matures; follow-up `2026-07-03-consolidate-godspeed-task-compatibility-cli` tracks consolidating it later.

The earlier scaffold used plausible but incorrect todo-item request shapes. Inspecting the existing helper showed the observed API contract is query-param `item_ids` for lookup and `client_id`/`update_bodies` for bulk updates, so tests now pin those shapes before dotfiles migration.

Stricli formats command-thrown errors itself, so CLI commands that need stable JSON errors should handle expected command failures inside the command helper instead of relying on an outer `try` around `run()`.

Bun did not hoist workspace-only runtime dependencies to root `node_modules`, so root-level typecheck/lint inspection was made deterministic by listing the runtime deps at the root too.

Replacing the executable `cli.ts` through patching reset its executable bit; the linked `godspeed` symlink then failed with `permission denied`. Restored `chmod +x packages/godspeed-cli/src/cli.ts` and verified the installed CLI afterward. Future changes to executable TS entrypoints should include a fresh installed-bin smoke check.
