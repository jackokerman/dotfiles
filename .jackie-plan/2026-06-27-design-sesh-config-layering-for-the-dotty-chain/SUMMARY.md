---
id: 2026-06-27-design-sesh-config-layering-for-the-dotty-chain
title: Design sesh config layering for the dotty chain
state: ready-to-implement
createdAt: 2026-06-27T19:49:58.297Z
updatedAt: 2026-06-27T19:53:31.832Z
---

# Summary

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
