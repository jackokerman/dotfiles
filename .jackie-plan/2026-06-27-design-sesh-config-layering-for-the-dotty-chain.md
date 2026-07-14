---
id: 2026-06-27-design-sesh-config-layering-for-the-dotty-chain
title: Design sesh config layering for the dotty chain
state: ready-to-implement
createdAt: 2026-06-27T19:49:58.297Z
updatedAt: 2026-07-14T18:32:09.408Z
---

# Design sesh config layering for the dotty chain

## Plan

## Problem

The repo already layers `sesh` config across the dotty chain, but it does so by blindly concatenating each repo's `home/.config/sesh/sesh.toml` into one generated live `~/.config/sesh/sesh.toml` during `dotty update`.

That works for simple additive snippets, but it is not an explicit extension model. It becomes risky when the chain needs clear ownership for:

- portable shared sessions that should work on personal machines and any host using this base repo
- host-specific or private sessions supplied by later repos in the dotty chain
- overlapping or duplicated session/window definitions
- scalar `sesh` settings such as `default_session`, `dir_length`, `git_dir_length`, `sort_order`, `blacklist`, `cache`, `separator_aware`, `tmux_command`, `[frecency]`, and `[tui]`
- long-lived local picker and remote-session glue that may overlap with upstream `sesh` functionality added since the last real audit

This plan is for the public/base-layer extensibility mechanism in `dotfiles`. It should not define private or host-specific session inventory; later repos own those fragments once the base layering contract exists.

## Current confirmations

- Repo inspection on 2026-07-14 shows `setup_sesh` in `.dotty/run.sh` still reads each repo's `home/.config/sesh/sesh.toml` from `~/.dotty/registry` and concatenates them into the live config.
- `tests/sesh/test-setup.sh` still only verifies concatenated whole-file output and symlink-to-real-directory migration. There is no import-aware or duplicate-aware regression coverage yet.
- This repo's tracked `home/.config/sesh/sesh.toml` currently only sets `dir_length = 2` and says session definitions belong in later repos.
- Local wrapper inspection on 2026-07-14 shows extra/non-local session behavior still lives outside native `sesh` config through `home/.local/bin/sesh-pick`, `home/.local/bin/sesh-one-shot`, `~/.cache/sesh-extra-entries`, and `~/.config/sesh/hooks/{refresh.d,connect.d}`.
- Homebrew currently provides `sesh` `v2.27.0`, released 2026-07-13. Host-managed Homebrew policy already permits the package on the work laptop, so no package-approval follow-up is needed before using the Homebrew binary.
- On this machine, `~/go/bin/sesh` is earlier on `PATH` than `/opt/homebrew/bin/sesh` and reports `sesh version dev`. Homebrew warns that the approved `sesh` binary is shadowed. The active mismatch is local PATH/manual-install cleanup, not package approval.
- Upstream `sesh` source on `main` still supports `import = [...]` in `sesh.toml`. Imports are resolved through `~`, environment variables, or absolute paths.
- Upstream import resolution appends only `[[session]]`, `[[window]]`, and `[[wildcard]]` entries from imported files. It does not merge or override scalar/root settings such as `cache`, `default_session`, `dir_length`, `git_dir_length`, `sort_order`, `blacklist`, `strict_mode`, `separator_aware`, `tmux_command`, `[frecency]`, or `[tui]`.
- Upstream wildcard behavior is order-sensitive: explicit `[[session]]` entries win over wildcards, and when multiple wildcards match, the first matching wildcard in config order wins.
- Upstream `v2.27.0` docs and release notes include functionality worth auditing before preserving local glue: native imports, reusable `[[window]]` layouts, wildcard windows, `sesh window`, `sesh mkdir`, opt-in cache plus `sesh cache refresh`, custom `[frecency]`, built-in picker TUI settings, `git_dir_length`, and `tmux_command`.
- Upstream issue review on 2026-07-14 shows `joshmedeski/sesh#234` and `joshmedeski/sesh#235` are still open. Maintainer guidance still points SSH-style dynamic sources toward static `[[session]]` entries today or a future custom-sources/rules design; the prior maintainer feedback on `#235` prefers `connect_command` terminology and treats cache quality/performance as first-class concerns.
- Current tracked docs already describe `home/.config/sesh/sesh.toml` as the portable baseline and say later repos own their own session definitions, but the implementation and tests still encode the older raw-concatenation contract.

## Target contract

Use `sesh`'s native import mechanism instead of building a general-purpose TOML merge layer.

The base repo should own one root `home/.config/sesh/sesh.toml` for global/scalar settings and portable defaults. Later repos in the dotty chain should contribute additive fragment files for `[[session]]`, `[[window]]`, and `[[wildcard]]` entries only.

`dotty update` should render a real live `~/.config/sesh/` directory containing:

- a generated root `~/.config/sesh/sesh.toml` copied from the base root config plus an `import = [...]` list
- generated imported fragment files under a stable live subdirectory such as `~/.config/sesh/imports/`
- import paths that are durable from any current working directory, preferably using `~/.config/...` paths or absolute live paths

The import list should preserve dotty registry order so wildcard precedence and visible listing order are deterministic.

## Concrete design decisions

- Keep global/scalar settings single-source in the base root `sesh.toml`. Later repos must not contribute whole root configs that change scalar behavior by concatenation.
- Add a portable base `home` session in this repo because it is useful on personal machines and generic across hosts. Use a stable identifier such as `name = "home"` and `path = "~"`. Do not bake an icon into the identifier unless the implementation verifies that `sesh-pick`, hook routing, and `sesh connect` all preserve a stable machine-readable name. Prefer native `sesh list --icons` or picker presentation for the home icon.
- Keep private, work, remote, and machine-family-specific sessions out of this public repo. Those belong in later repo fragments after the import contract lands.
- Treat duplicate `[[session]].name` and duplicate `[[window]].name` across the generated root and all imported fragments as clear `dotty update` errors. Do not silently shadow or invent partial override semantics.
- Do not fail on duplicate or overlapping `[[wildcard]].pattern` in v1. Follow upstream first-match ordering and document that later repos can narrow behavior only by controlling fragment order, not by overriding earlier wildcard entries.
- Start with the generator inline in `.dotty/run.sh`, matching the current setup style. Move it to a small Bun/TypeScript helper only if duplicate detection, import rendering, or validation makes the shell implementation meaningfully hard to read.
- Prefer current upstream `sesh` features over local wrappers where they directly replace existing behavior. Keep local wrappers only when they still solve a concrete need that upstream does not cover.

If real override pressure remains after the import-based design lands, capture a separate second-phase plan for explicit merge/override semantics instead of smuggling override behavior into concatenation.

## Implementation slices

1. Verify the effective `sesh` binary before coding. Resolve any stale `PATH` shadowing or explicitly use the intended binary for docs/source checks and smoke tests.
2. Re-check upstream `sesh` docs/source for the current `import`, `window`, `wildcard`, `cache`, `frecency`, `picker`, `mkdir`, `git_dir_length`, and `tmux_command` behavior. Record only implementation-relevant adopt/keep/ignore conclusions in repo docs.
3. Trace the existing producer/consumer path for `setup_sesh`: tracked source config, dotty registry traversal, live `~/.config/sesh/` output, `sesh-pick`, hook directories, docs, and tests.
4. Replace raw multi-repo concatenation of `home/.config/sesh/sesh.toml` with a root-config plus imported-fragments model.
5. Define the tracked fragment contract for later repos. Recommended shape:
   - base repo owns `home/.config/sesh/sesh.toml`
   - later repos own additive files under `home/.config/sesh/imports/*.toml`
   - imported files may contain `[[session]]`, `[[window]]`, and `[[wildcard]]` only
6. Add the base `home` session in the portable root or a first-party base fragment, keeping `home` as the stable identifier.
7. Generate live imported fragments into the real `~/.config/sesh/imports/` directory during `dotty update`, with durable import paths in the generated root config.
8. Add validation and focused regression coverage for import generation order, symlink-to-real-directory migration, duplicate session/window detection, rejection of scalar settings in imported fragments, stale generated-fragment cleanup, and import-path durability.
9. Update `README.md`, `AGENTS.md`, and any deeper docs that mention `sesh` ownership or generated config. Replace the old implicit whole-file concatenation model with the new root-plus-imports contract.
10. Revisit `sesh-pick` and `sesh-one-shot` after the generation contract works. Use upstream `sesh cache refresh`, built-in picker behavior, window management, or other native features only where they clearly simplify current local glue without losing remote-session support.
11. Give the SSH/custom-sources path an explicit disposition. Either leave the local workaround with rationale, post a concise update on `joshmedeski/sesh#235`, cross-link `#234` as effectively subsumed by `#235`, or capture a separate upstream follow-up plan. Do not block the base layering change on upstream work.
12. Capture any private or host-specific session migration as follow-up work in the later repo after the base layering mechanism exists.

## Acceptance criteria

- The public base repo defines portable `sesh` defaults and a generic `home` session without copying private or host-specific session definitions into this repo.
- Later repos in the dotty chain can add `sesh` sessions, windows, and wildcards by adding import fragments, without editing the base root `sesh.toml`.
- `dotty update` produces a durable working `~/.config/sesh/sesh.toml` plus imported fragment files under the real live `~/.config/sesh/` directory.
- Generated imports preserve dotty registry order.
- Duplicate session/window definitions fail clearly during generation or validation instead of shadowing silently.
- Imported fragments cannot change scalar/root settings by accident.
- Wildcard precedence stays aligned with upstream first-match behavior and is documented.
- The implementation records which current local `sesh` customizations are still justified after checking current upstream functionality.
- The SSH/custom-sources path has an explicit disposition, even if the disposition is to keep the local workaround and defer upstream work.
- Docs and regression tests describe and protect the new layering contract.

## Verification to run when implementing

- `command -v sesh`, `sesh --version`, and the package-manager `sesh` binary if PATH shadowing is present
- `sesh --help`, `sesh list --help`, `sesh picker --help`, and help for any newly adopted commands such as `sesh cache`, `sesh window`, or `sesh mkdir`
- the focused `tests/sesh/` regression lane
- `dotty update`
- a live smoke test such as `sesh list -c` after generation
- direct picker smoke verification if `sesh-pick` labels, icons, hooks, or cache behavior change
- `./scripts/check --quiet`, or `./scripts/check --extended --quiet` if the change touches broad generated-config, shell helper, or tmux/picker behavior
- `git status --short --branch` before any commit/push

## Next honest step

Complete the source-linked `sesh` binary provenance cleanup plan first so the Homebrew `sesh` binary is the effective `sesh` command. Then update `setup_sesh` and `tests/sesh/test-setup.sh` around the new root-plus-imports contract before touching picker or remote-session behavior.

## Agent handoff

Cleaned up the ready-to-implement contract on 2026-07-14 after user-led refinement.

Kept the import-based direction, removed the stale duplicated handoff body, updated upstream/local confirmations for current `sesh` `v2.27.0`, and made the personal/base-vs-later-repo boundary explicit. Added a concrete base `home` session requirement with stable identifier guidance, clarified that icons should stay presentation unless verified across picker/connect boundaries, and kept private/host-specific sessions routed to later repo fragments.

Follow-up research confirmed `sesh` is already permitted by host-managed Homebrew policy on the work laptop, so package approval is not a blocker. The remaining prerequisite is local binary precedence cleanup: `~/go/bin/sesh` shadows `/opt/homebrew/bin/sesh`, so the source-linked cleanup plan should make the Homebrew binary effective before implementing this config-layering plan.
