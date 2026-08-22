---
id: 2026-08-22-replace-tmux-agent-bar-with-fleet
title: Replace tmux-agent-bar with Fleet
state: complete
createdAt: 2026-08-22T19:10:10.292Z
updatedAt: 2026-08-22T22:16:28.334Z
---

# Replace tmux-agent-bar with Fleet

## Plan

## Objective

Replace the active `tmux-agent-bar` runtime and dotfiles integration with upstream `nicknisi/fleet`, installed through Homebrew, while preserving the existing Nightfly Fleet palette and providing a native Fleet status row, sidebar, and popup workflow. After the Fleet cutover is verified and pushed, change `jackokerman/tmux-agent-bar` from public to private.

The migration is complete when fresh Codex sessions report through Fleet, tmux no longer invokes or manages `tmux-agent-bar`, the Homebrew binary wins on `PATH`, the public dotfiles repo no longer depends on the old repository, and GitHub reports the old repository as private. Claude Code is deliberately uninstalled and removed from the tracked Brewfile at the user's request; its dormant dotfiles configuration remains available for a future reinstall but is not an acceptance requirement.

## Confirmed context

- Fleet upstream release `v0.22.2` at `407cc240589673eab054cef2a0808e54d4726d8d` is current as of 2026-08-22 and ships macOS and Linux Homebrew assets through `nicknisi/formulae/fleet`.
- The custom Nightfly palette contribution was merged upstream in `nicknisi/fleet#53`; `home/.config/fleet/theme.toml` can remain the single tracked palette source.
- This machine currently resolves `fleet` through `~/.local/bin/fleet -> ~/src/fleet/dist/fleet`, a development build based on the older `v0.18.2` line. That symlink would shadow Homebrew until explicitly removed.
- The existing dotfiles config already binds prefixless `Ctrl-f` in the tmux `root` and nested-pass-through `off` tables to a 55% by 60% Fleet popup.
- The default prefix table still uses `f` for tmux's built-in find-window and `n` for next-window.
- Fleet natively provides a two-row tmux status line, a toggleable 34-column sidebar, a dashboard popup, next-waiting navigation, Claude plugin hooks, Codex hooks, health checks, and hookless process discovery.
- Nick Nisi's current dotfiles use `prefix-f` for the sidebar, a separate large popup binding, `prefix-n` for `fleet next`, and Fleet's native second status row.
- `tmux-agent-bar` is currently public, clean, and synchronized with `origin/main`. It currently has no forks, stars, watchers, Pages site, or Actions runs; it has one open issue. Recheck these facts immediately before the visibility change.
- No later dotty-chain repo currently contains a `tmux-agent-bar` or Fleet integration override.

## User-facing workflow

- `Ctrl-f`, without prefix, continues to open Fleet in the existing 55% by 60% popup from normal local tmux mode and nested pass-through mode.
- `prefix-f` toggles Fleet's native 34-column sidebar in the invoking window using `fleet sidebar --from '#{pane_id}'`.
- Fleet's native second tmux status row is an attention queue: it always shows the sidebar button and adds clickable agents only for permission, question, and ready/done states. Working and idle agents remain visible in the dashboard and sidebar instead of the status row.
- Do not add Fleet's optional `prefix-F` popup because the direct `Ctrl-f` popup already owns that workflow.
- Do not adopt Nick's `prefix-n` binding in this migration. Preserve tmux's current next-window behavior; `fleet next` remains available as a command and can earn a binding later.
- Keep Fleet's window-list state rollup disabled. It replaces themed window formats and is not required for the initial adoption.
- Keep the existing Nightfly `theme.toml` unchanged unless current upstream validation exposes a real incompatibility.

## Implementation plan

### 1. Establish the Homebrew source of truth

- Add `nicknisi/formulae` and `nicknisi/formulae/fleet` to the personal-only section of the tracked `Brewfile`.
- Remove the tracked `claude-code` cask and uninstall that exact Homebrew cask. Preserve dormant `home/.claude` configuration so a future reinstall plus `dotty update` can restore integration.
- Update setup documentation to name Fleet as the agent dashboard and explain that Homebrew owns the executable while dotfiles own the reviewed integration.
- Install the tracked Fleet formula with the normal `dotty run brew-sync` path.
- Verify the formula and upstream version before removing anything: `brew list --versions fleet`, `brew info nicknisi/formulae/fleet`, and the Homebrew binary's `fleet --version`.
- Confirm the merged palette contribution is present upstream, then remove only the obsolete `~/.local/bin/fleet` symlink. Do not delete `~/src/fleet`; it remains a contribution checkout.
- Verify `command -v fleet` and `type -a fleet` resolve the Homebrew executable rather than the development symlink.

### 2. Wire Fleet through tracked configuration

- Add a small install-time Fleet setup step to the existing dotty hook, gated on `fleet` and the applicable agent CLIs being available. Use Fleet's native `fleet install` and `fleet install codex` commands to establish the Claude marketplace/plugin registration, the upgrade-stable Fleet plugin link, Codex status directory, and Fleet agent registry.
- Run the native installers non-interactively during setup so they do not append optional keybindings or pause for prompts. Treat a missing optional agent CLI as a scoped warning rather than preventing the rest of dotty installation.
- Keep the stable Codex hook command in the tracked `home/.codex/hooks.json` source so a later `dotty update` cannot overwrite Fleet's integration. Retain only Fleet's supported Codex `PreToolUse` and `Stop` entries and keep `[features].hooks = true`.
- Remove only the old tmux agent-state hooks from tracked Claude settings. Preserve the unrelated conventional-commit validation hook and other Claude settings. Persist Fleet's enabled plugin entry so copying the tracked settings on later updates does not silently disable the installed plugin.
- Update the existing Codex config tests to assert Fleet's stable hook contract rather than the deleted adapter wrapper.

### 3. Replace the tmux surface

- Keep the existing direct `Ctrl-f` popup bindings in the `root` and `off` tables.
- Add a documented `prefix-f` binding for `fleet sidebar --from '#{pane_id}'`, deliberately replacing the built-in find-window binding.
- Add the tracked Fleet statusline injection line after the Nightfly theme is loaded so every new or reloaded tmux server receives Fleet's native second row and click bindings.
- Remove the `tmux-agent-bar` current-session prefix, cached `status-right`, refresh hooks, session-close hook, and nested-pass-through references. Let Nightfly own the normal first-row session/window styling and Fleet own the second agent row.
- Do not enable Fleet window-state rollup or add a second popup binding.

### 4. Remove the obsolete integration

- Remove the `tmux-agent-bar` row from `.dotty/managed-checkouts.tsv`.
- Remove the dedicated sync command and script, runtime path resolver, status/render/refresh wrappers, Claude/Codex adapter wrappers, and their focused tests.
- Remove the obsolete `tmux-agent-bar` test phase and path routing from `scripts/check`. Keep shared test helpers if other active tests still consume them; rename or relocate a helper only if its old directory name becomes misleading.
- Rewrite `home/.config/tmux/README.md`, the tmux/Fleet portion of `docs/agent-tooling.md`, repo-root `AGENTS.md`, and the relevant setup/command material in `README.md` around the Fleet source of truth, native bindings, hook ownership, and verification.
- Do not rewrite historical Jackie Plan artifacts merely because they mention `tmux-agent-bar`.
- Do not delete either local development checkout or old cache/state until the new path is verified. After successful cutover, remove obsolete `~/.cache/tmux-agent-bar` runtime cache only; preserve both Git checkouts.

### 5. Verify and publish the dotfiles cutover

- Run focused syntax and config checks for the changed shell, JSON, TOML, and tmux files.
- Load the config on an isolated tmux socket and verify:
  - `status` has two rows;
  - `status-format[1]` invokes `fleet status --statusline`;
  - `prefix-f` targets the invoking pane and toggles one sidebar;
  - direct `Ctrl-f` remains present in both `root` and `off`;
  - no active tmux option, hook, or process command references `tmux-agent-bar`.
- Run `fleet doctor`.
- Start a fresh Codex session inside tmux so it loads the new integration. Confirm it appears in Fleet, transitions through working and ready states, and produces the clickable ready chip. Verify the popup and sidebar expose working and idle sessions.
- Run `./scripts/check --extended --quiet`.
- Commit the owned dotfiles changes conventionally and push `main`. Run `dotty update` after the commit, reload the live tmux config, and repeat the narrow live checks. Stop for unrelated dirty overlap, unexpected ahead commits, or non-fast-forward remote state.

### 6. Make the retired repository private

- Only after the pushed dotfiles configuration and live Fleet workflow pass, recheck `jackokerman/tmux-agent-bar` visibility, forks, stars/watchers, Pages, Actions, open changes, and clean synchronized local state.
- Change visibility with `gh repo edit jackokerman/tmux-agent-bar --visibility private --accept-visibility-change-consequences`.
- Verify GitHub reports `PRIVATE` and that the authenticated local checkout can still fetch.
- Do not archive or delete the repository, rewrite its history, remove its local checkout, or close its remaining issue as part of this migration.
- Record that GitHub erases stars/watchers and detaches public forks when a public repository becomes private; the current preflight reports none, but the implementation must use the fresh preflight result.

## Non-goals

- Do not maintain a compatibility path between Fleet and `tmux-agent-bar`.
- Do not teach Fleet to consume `tmux-agent-bar` state.
- Do not add remote-agent adapters, window rollup, new Fleet theme work, new status parsing, or custom Fleet wrappers.
- Do not copy Nick Nisi's entire tmux layout or keymap.
- Do not make `nicknisi/fleet` or the existing Fleet contribution checkout private.
- Do not delete preservation-sensitive Git repositories during cleanup.

## Failure and rollback boundaries

- Do not remove the development Fleet symlink until the Homebrew binary is installed and directly executable.
- Do not remove old hooks/status integration until Fleet's native installers and tracked replacement config are ready in the same change.
- If Fleet's status row or hooks fail before the dotfiles commit, restore the old tracked integration from the still-public, preserved checkout and keep the repository public.
- If the dotfiles cutover is pushed but the final visibility change fails, leave Fleet active and report the privacy step as the only incomplete item; do not reintroduce `tmux-agent-bar`.
- Once GitHub accepts the visibility change, rollback means explicitly making the repository public again and carries GitHub's visibility-change consequences. Do not perform that reversal without a new user request.

## Acceptance criteria

- Fleet is installed from `nicknisi/formulae/fleet`, and no earlier executable shadows it.
- The direct popup, prefix sidebar, native second status row, and Codex state all work in a fresh tmux session.
- Claude Code is absent from the tracked Brewfile and the installed Homebrew casks; dormant tracked Claude configuration remains preserved for a future reinstall.
- The active dotfiles tree, generated live config, managed checkout manifest, and tmux server contain no runtime dependency on `tmux-agent-bar`.
- The Nightfly Fleet palette still loads.
- Extended repository validation passes.
- The dotfiles changes are committed and pushed to `main`, then applied with `dotty update`.
- `jackokerman/tmux-agent-bar` reports private visibility and remains fetchable through the authenticated local checkout.

## Next honest step

No implementation work remains. Restart any Codex process that was already running before the generated Fleet hooks changed so it loads the clean `PreToolUse` and `Stop` configuration.

## Agent handoff

The Fleet migration is complete and the user approved the final Codex-only scope. Homebrew Fleet 0.22.2 owns the executable; the tracked and live tmux/Codex integration uses Fleet's native attention row, popup, sidebar, and PreToolUse/Stop hooks; the old checkout integration, wrappers, managed checkout, tests, active server hooks, and runtime cache are gone. The 36 KB cache was moved to `~/.Trash/tmux-agent-bar-2026-08-22`, where it remains recoverable until Trash is emptied. Both development checkouts remain preserved.

Fresh Codex verification observed IDLE, BUSY, and DONE with both Fleet hooks completing and a ready chip rendering. The live config has two status rows, the exact Fleet statusline command, both direct Ctrl-f bindings, pane-targeted prefix-f, and no tmux-agent-bar runtime references. Extended validation passed. Claude Code 2.1.231 was intentionally removed from the Brewfile and Homebrew installation; dormant tracked and live Claude configuration remain for a future reinstall. Fleet 0.22.2 doctor has an upstream no-Claude spawn bug, but Fleet's Codex JSON/status path remains healthy.

The dotfiles cutover commits f82a8fd and 860959c and activation checkpoint a2618b8 are on origin/main. `jackokerman/tmux-agent-bar` passed preflight with zero forks, stars, watchers, Pages, Actions runs, or open pull requests and one preserved open issue. GitHub now reports PRIVATE, unarchived, enabled, non-forked visibility with authenticated admin access. The first configured fetch immediately after the visibility transition received a transient disabled response; subsequent HTTPS and SSH ls-remote checks and the configured origin fetch all succeeded. The local checkout is clean and synchronized at b6b3e8d.

The plan is complete. The lifecycle artifact is included in the current approved dotfiles commit-and-push scope; no commit or push result for that final artifact is claimed yet. No follow-up was captured, and the improvement audit found no additional dotfiles steering change warranted. Existing pre-migration Codex processes should be restarted to load the clean generated hooks.
