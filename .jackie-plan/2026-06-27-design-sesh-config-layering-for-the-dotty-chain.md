---
id: 2026-06-27-design-sesh-config-layering-for-the-dotty-chain
title: Design sesh config layering for the dotty chain
state: ready-to-implement
createdAt: 2026-06-27T19:49:58.297Z
updatedAt: 2026-06-27T19:53:31.832Z
---

# Design sesh config layering for the dotty chain

## Plan

## Problem

The repo already layers `sesh` config across the dotty chain, but it does so by blindly concatenating each repo's `home/.config/sesh/sesh.toml` into one generated live file during `dotty update`.

That works for simple additive snippets, but it is not an explicit extension model and it breaks down once we need clearer ownership for:

- portable shared sessions defined in the public base repo
- private or work-specific sessions defined in later repos
- overlapping or duplicated session/window definitions
- scalar `sesh` settings such as `default_session`, `dir_length`, `sort_order`, `blacklist`, and `[tui]`
- long-lived local `sesh` glue that may now overlap with upstream features added since the last real audit

This plan is only for the public/base-layer extensibility mechanism in `dotfiles`. It does not try to define the work-specific session inventory itself; that belongs in a later repo once the layering contract exists.

## Confirmed findings

- Local repo inspection on 2026-06-27 shows `setup_sesh` in `.dotty/run.sh` reading each repo's `home/.config/sesh/sesh.toml` from `~/.dotty/registry` and concatenating them into live `~/.config/sesh/sesh.toml`.
- Local test inspection on 2026-06-27 shows `tests/sesh/test-setup.sh` only verifying concatenated fragment output; there is no session-aware merge contract yet.
- Local tracked config inspection on 2026-06-27 shows this repo's `home/.config/sesh/sesh.toml` currently only sets `dir_length = 2`.
- Local wrapper inspection on 2026-06-27 shows remote/non-local session behavior currently lives outside native `sesh` config, via `home/.local/bin/sesh-pick`, `~/.cache/sesh-extra-entries`, and `~/.config/sesh/hooks/{refresh.d,connect.d}`.
- Local CLI verification on 2026-06-27 confirmed `sesh version 2.26.2`.
- Upstream `sesh` source verification on 2026-06-27 confirmed native `import = [..]` support in `sesh.toml`.
- Upstream parser verification on 2026-06-27 confirmed imports only append `[[session]]`, `[[window]]`, and `[[wildcard]]` entries. They do not merge or override `default_session`, `dir_length`, `sort_order`, `blacklist`, `tmux_command`, `strict_mode`, or `[tui]`.
- Upstream README/source verification on 2026-06-27 confirmed wildcard precedence is order-sensitive: if multiple wildcard configs match, the first one in config order wins.
- Upstream release review on 2026-06-27 confirmed recent feature growth that this repo has not audited yet, especially `v2.25.0` on 2026-04-13 adding wildcard config improvements, reusable windows for wildcards, pane listing/connection, and tmux window management.
- Upstream issue review on 2026-06-27 confirmed:
  - `joshmedeski/sesh#234` (`sesh list option for ssh config`) has been open since 2025-03-07, with maintainer guidance pointing users toward static `[[session]]` entries or the broader custom-sources idea.
  - `joshmedeski/sesh#235` (`Custom Sources`) has been open since 2025-03-07 and was updated on 2026-03-31 after a follow-up proposal from `jackokerman`; the maintainer said they are open to a purely additive PR, suggested `connect_command` terminology, and called out cache quality/performance concerns.
- Current tracked docs already describe `home/.config/sesh/sesh.toml` as the portable baseline and say later repos own their own session definitions, but the implementation contract is still only raw concatenation.

## Recommended direction

Do not start with a general-purpose TOML merge CLI.

Start with `sesh`'s native import mechanism and make the layering contract explicit:

- Keep one root `sesh.toml` owner in the base repo for global/scalar settings and any portable defaults that should remain single-source.
- Keep portable shared `[[session]]` entries in that root config unless they clearly benefit from moving into a first-party fragment later.
- Introduce additive tracked fragment files for later repos, likely under something like `home/.config/sesh/imports/`, for `[[session]]`, `[[window]]`, and `[[wildcard]]` entries only.
- Have `setup_sesh` generate live `~/.config/sesh/imports/*.toml` files and a root live `~/.config/sesh/sesh.toml` that references them through durable `~/.config/...` import paths.
- Preserve dotty registry order when generating the import list so layering remains predictable.
- Treat duplicate session/window names across fragments as an explicit error in v1 rather than silently shadowing or inventing partial override semantics.
- Keep duplicate or overlapping wildcard behavior aligned with upstream ordering rules in v1; document the precedence clearly instead of trying to outsmart it.
- Keep the generator inline in `.dotty/run.sh` for the first implementation pass. Move it to a Bun/TypeScript helper only if the final contract becomes too awkward to maintain inline.

If real override pressure still remains after the import-based design lands, then design a second-phase merge layer with an explicit override contract instead of smuggling that behavior into concatenation.

## Companion sesh hygiene track

Pair the layering change with a small `sesh` hygiene audit so we stop carrying stale local complexity by accident.

The audit should explicitly compare the current local wrapper surface against upstream features now available in `sesh`, especially:

- native `import` support
- wildcard configs and wildcard windows
- reusable `[[window]]` layouts
- pane and window management commands
- opt-in cache behavior
- built-in picker TUI capabilities
- `tmux_command` / multiplexer support

The goal is not to rewrite the workflow around every new upstream feature. The goal is to decide which local customizations are still justified, which should be simplified, and which should remain because they solve needs upstream still does not cover.

## Upstream SSH/custom-sources follow-up

Treat the remote-session path as an explicit upstream follow-up, not hidden local lore.

- Re-read the current local remote-session hooks alongside upstream issues `#234` and `#235`.
- Decide whether the right next move is:
  - keep the local workaround and post a short status update on `#235`
  - narrow and close `#234` as effectively subsumed by `#235`
  - or intentionally defer upstream work with a recorded reason if the local layering change reduces urgency
- If the custom-sources direction still looks worth pursuing, keep any future proposal aligned with the maintainer feedback already given on 2026-03-31: prefer `connect_command` terminology and treat cache behavior/performance as first-class design constraints.

## Why this is the right first slice

- `sesh` already exposes a supported extension boundary for the additive parts that matter most here: sessions, windows, and wildcards.
- A custom merge tool immediately creates hard questions around scalar ownership, wildcard precedence, duplicate-name policy, and future docs burden.
- The stated need sounds like base shared sessions plus later-repo session additions, which imports can solve without adding a second config language or control surface.
- The repo's tracked `sesh` config is currently minimal, so a targeted audit has a good chance of simplifying the setup instead of merely moving complexity around.
- This keeps one explicit source of truth for global settings while still letting later repos contribute their own session sets.

## Implementation slices

1. Audit current local `sesh` usage against recent upstream features and record explicit adopt/ignore decisions for imports, windows, wildcards, panes, cache, picker, and multiplexer support.
2. Re-read the local remote-session workaround and upstream issues `#234`/`#235`, then record the intended upstream follow-up so the SSH/custom-sources direction is not left ambiguous.
3. Trace the current producer/consumer path for `setup_sesh` across tracked source, registry traversal, live output, docs, and tests.
4. Replace the current multi-repo concatenation of `home/.config/sesh/sesh.toml` with a single root-config model plus imported fragment discovery.
5. Define and document the tracked fragment contract for later repos.
   Example contract:
   - the base repo owns `home/.config/sesh/sesh.toml`
   - later repos own only fragment files for `[[session]]`, `[[window]]`, and `[[wildcard]]`
6. Generate live imported fragments into the real `~/.config/sesh/` directory during `dotty update` using durable paths that do not depend on the caller's current working directory.
7. Add validation and regression coverage for:
   - import generation order
   - existing symlink-to-real-directory migration behavior
   - duplicate session/window detection
   - import-path durability
8. Update `README.md`, `AGENTS.md`, and any deeper docs to document the new ownership model, the hygiene conclusions, and the removal of the old implicit concatenation contract.
9. Capture any work/private follow-up in the later repo only after the base layering mechanism exists.

## Acceptance criteria

- The public base repo can define portable `sesh` defaults and shared sessions without copying work/private session definitions into this repo.
- Later repos in the dotty chain can add `sesh` sessions, windows, and wildcards without editing the base repo's root `sesh.toml`.
- `dotty update` produces a durable working `~/.config/sesh/sesh.toml` plus any imported fragment files.
- Duplicate session/window definitions fail clearly instead of shadowing silently.
- Order-sensitive upstream behavior stays deterministic and documented.
- The implementation records which current local `sesh` customizations are still justified after auditing current upstream features.
- The SSH/custom-sources path has an explicit disposition: update `#235`, deliberately leave it alone with rationale, and/or close or cross-link `#234` if it is effectively subsumed.
- Docs and regression tests describe and protect the new contract.

## Verification to run when implementing

- `sesh --help`
- the focused `tests/sesh/` regression lane
- `dotty update`
- a live smoke test such as `sesh list -c` after generation
- `./scripts/check --quiet` or `./scripts/check --extended --quiet`, depending on final change scope
- `git status --short --branch` before any commit/push

## Agent handoff

# Design sesh config layering for the dotty chain

## Plan

## Problem

The repo already layers `sesh` config across the dotty chain, but it does so by blindly concatenating each repo's `home/.config/sesh/sesh.toml` into one generated live file during `dotty update`.

That works for simple additive snippets, but it is not an explicit extension model and it breaks down once we need clearer ownership for:

- portable shared sessions defined in the public base repo
- private or work-specific sessions defined in later repos
- overlapping or duplicated session/window definitions
- scalar `sesh` settings such as `default_session`, `dir_length`, `sort_order`, `blacklist`, and `[tui]`

This plan is only for the public/base-layer extensibility mechanism in `dotfiles`. It does not try to define the work-specific session inventory itself; that belongs in a later repo once the layering contract exists.

## Confirmed findings

- Local repo inspection on 2026-06-27 shows `setup_sesh` in `.dotty/run.sh` reading each repo's `home/.config/sesh/sesh.toml` from `~/.dotty/registry` and concatenating them into live `~/.config/sesh/sesh.toml`.
- Local test inspection on 2026-06-27 shows `tests/sesh/test-setup.sh` only verifying concatenated fragment output; there is no session-aware merge contract yet.
- Local CLI verification on 2026-06-27 confirmed `sesh version 2.26.2`.
- Upstream `sesh` source verification on 2026-06-27 confirmed native `import = [..]` support in `sesh.toml`.
- Upstream parser verification on 2026-06-27 confirmed imports only append `[[session]]`, `[[window]]`, and `[[wildcard]]` entries. They do not merge or override `default_session`, `dir_length`, `sort_order`, `blacklist`, `tmux_command`, `strict_mode`, or `[tui]`.
- Upstream README/source verification on 2026-06-27 confirmed wildcard precedence is order-sensitive: if multiple wildcard configs match, the first one in config order wins.
- Current tracked docs already describe `home/.config/sesh/sesh.toml` as the portable baseline and say later repos own their own session definitions, but the implementation contract is still only raw concatenation.

## Recommended direction

Do not start with a general-purpose TOML merge CLI.

Start with `sesh`'s native import mechanism and make the layering contract explicit:

- Keep one root `sesh.toml` owner in the base repo for global/scalar settings and any portable defaults that should remain single-source.
- Introduce additive tracked fragment files for session definitions across the dotty chain, likely under something like `home/.config/sesh/imports/`.
- Have `setup_sesh` generate live `~/.config/sesh/imports/*.toml` files and a root live `~/.config/sesh/sesh.toml` that references them through durable `~/.config/...` import paths.
- Preserve dotty registry order when generating the import list so layering remains predictable.
- Treat duplicate session/window names across fragments as an explicit error in v1 rather than silently shadowing or inventing partial override semantics.

If real override pressure still remains after the import-based design lands, then design a second-phase merge layer with an explicit override contract instead of smuggling that behavior into concatenation.

## Why this is the right first slice

- `sesh` already exposes a supported extension boundary for the additive parts that matter most here: sessions, windows, and wildcards.
- A custom merge tool immediately creates hard questions around scalar ownership, wildcard precedence, duplicate-name policy, and future docs burden.
- The stated need sounds like base shared sessions plus later-repo session additions, which imports can solve without adding a second config language or control surface.
- This keeps one explicit source of truth for global settings while still letting later repos contribute their own session sets.

## Implementation slices

1. Trace the current producer/consumer path for `setup_sesh` across tracked source, registry traversal, live output, docs, and tests.
2. Replace the current multi-repo concatenation of `home/.config/sesh/sesh.toml` with a single root-config model plus imported fragment discovery.
3. Define the tracked fragment contract for later repos.
   Example contract:
   - the base repo owns `home/.config/sesh/sesh.toml`
   - later repos own only fragment files for `[[session]]`, `[[window]]`, and `[[wildcard]]`
4. Generate live imported fragments into the real `~/.config/sesh/` directory during `dotty update` using durable paths that do not depend on the caller's current working directory.
5. Add validation and regression coverage for:
   - import generation order
   - existing symlink-to-real-directory migration behavior
   - duplicate session/window detection
   - import-path durability
6. Update `README.md`, `AGENTS.md`, and any deeper docs to document the new ownership model and remove the old implicit concatenation contract.
7. Capture any work/private follow-up in the later repo only after the base layering mechanism exists.

## Acceptance criteria

- The public base repo can define portable `sesh` defaults and shared sessions without copying work/private session definitions into this repo.
- Later repos in the dotty chain can add `sesh` sessions, windows, and wildcards without editing the base repo's root `sesh.toml`.
- `dotty update` produces a durable working `~/.config/sesh/sesh.toml` plus any imported fragment files.
- Order-sensitive upstream behavior stays deterministic and documented.
- Duplicate session/window definitions fail clearly instead of shadowing silently.
- Docs and regression tests describe and protect the new contract.

## Open decisions to resolve during implementation

- Whether portable shared `[[session]]` entries should stay in the root `sesh.toml` or move into a first-party imported fragment for symmetry.
- Whether duplicate wildcard patterns should also fail or simply follow import order, since upstream wildcard precedence is intentionally order-based.
- Whether the live generator should stay inline in `.dotty/run.sh` or move to a small Bun/TypeScript helper once the contract is concrete. Start inline unless the implementation proves too awkward.

## Verification to run when implementing

- `sesh --help`
- the focused `tests/sesh/` regression lane
- `dotty update`
- a live smoke test such as `sesh list -c` after generation
- `./scripts/check --quiet` or `./scripts/check --extended --quiet`, depending on final change scope
- `git status --short --branch` before any commit/push
