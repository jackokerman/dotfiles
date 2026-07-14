---
id: 2026-06-26-design-config-driven-devtool-repo-management
title: Design config-driven devtool repo management
state: complete
createdAt: 2026-06-26T17:42:12.482Z
updatedAt: 2026-07-14T17:49:59.528Z
sourcePlan: 2026-06-26-implement-integrated-dev-tool-metadata-for-jackie-plan
---

# Design config-driven devtool repo management

## Plan

Design and implement the next slice of config-driven devtool repo management for this dotty setup. The goal is that personal development tools can be declared in one tracked dotty manifest, and dotty can make the corresponding repos exist, keep them reasonably current, and run the right install or sync step without each tool needing bespoke repo metadata and glue in `.dotty/run.sh`.

## Product Goal

A reusable personal devtool should be addable by editing one declarative config surface plus, when needed, one installer command. For each configured tool, the config should say where the repo comes from, where it should live, how it updates, and what install dispatch, if any, runs after checkout. Running `dotty update` should converge the machine toward that declared state.

This is for personal tooling, not a public package manager. Prefer a direct model that is easy to inspect and fix locally over compatibility layers for hypothetical external users. If an old path or legacy behavior is obsolete, remove it or migrate it deliberately instead of preserving it indefinitely.

## Current State

- `.dotty/dev-checkouts.tsv` declares development checkouts with `name`, repo URL, and branch.
- `scripts/sync-dev-checkouts.sh` clones missing repos under `~/src` and fast-forwards clean checkouts on their configured branch.
- Tool-specific install integration is separate. Jackie Plan has `.dotty/commands/install-jackie-plan`, and GodspeedJS is installed by bespoke `setup_godspeed_js` logic in `.dotty/run.sh`.
- Jackie Plan still repeats repo URL, branch, and checkout path in its installer even though the checkout is also declared in `.dotty/dev-checkouts.tsv`.
- Existing docs distinguish active contribution checkouts under `~/src` from runtime implementation checkouts under `~/.local/share`.
- The old Jackie Plan runtime checkout has an explicit cleanup task, so ongoing compatibility symlink behavior should be re-evaluated instead of preserved automatically.

## Config Format Decision

Use a richer line-oriented TSV manifest rather than YAML, JSON, or sourced Bash arrays. This repo already parses TSV in Bash, and TSV keeps `dotty update` independent of `yq`, `jq`, Ruby, Node, Bun, or Python being available during early setup.

Rename the manifest to `.dotty/devtools.tsv`. The manifest now owns both checkout sync and optional install dispatch, so devtools-oriented naming is clearer than keeping checkout-only names. Preserve a `dotty run sync-devtools` command surface. Keep `dotty run sync-dev-checkouts` only if the implementation finds a real current caller that needs a short compatibility wrapper; otherwise remove or migrate the old command in the same change.

Do not make the manifest executable shell code. The manifest should stay declarative data that Bash can parse with `IFS=$'\t' read -r ...`, validate per row, and report clearly when a row is malformed.

A likely first schema is:

- `name`: stable tool identifier and default checkout directory name.
- `repo`: Git remote URL.
- `branch`: branch to clone or fast-forward.
- `checkout`: checkout location, initially either `dev` for `~/src/<name>` or an explicit path when there is a concrete need.
- `update`: update policy, initially conservative fast-forward only.
- `install`: optional install dispatch.

Skip `enabled` until there is an immediate need to keep a declaration but skip it on this machine. Do not add fallback paths, compatibility symlink fields, multiple location aliases, or per-machine override machinery in this slice.

## Install Dispatch Model

Keep install dispatch as a manifest field, but keep substantive install behavior in scripts.

Prefer repo-owned installers when the repo has a normal self-install command, such as `scripts/install.sh` or a package-manager script. Use dotfiles-owned commands when the install step is host integration rather than repo build logic: PATH wrapper generation, compatibility cleanup, dotty-specific linking, combining several repo commands, or adapting a repo-owned installer to this dotty environment.

The manifest should point to one install action using a small explicit convention rather than embedding arbitrary shell. The first convention is:

- empty install field: checkout-only tool.
- `repo:<relative-command>`: run a command from the configured checkout, with the checkout as the working directory.
- `dotty:<relative-command>`: run a command from the dotfiles repo, with the dotfiles repo as the working directory.

Install actions should receive configured metadata only through named environment variables, not synthetic positional arguments. Use a small `DOTTY_DEVTOOL_*` contract:

- `DOTTY_DEVTOOL_NAME`: manifest tool name.
- `DOTTY_DEVTOOL_CHECKOUT_DIR`: resolved checkout path.
- `DOTTY_DEVTOOL_REPO_URL`: configured Git remote URL.
- `DOTTY_DEVTOOL_BRANCH`: configured branch.

Do not pass the same metadata through both positional args and environment variables. The install command's normal positional interface should remain available for repo-owned scripts that humans may also run directly. Repo-owned installers may ignore the `DOTTY_DEVTOOL_*` variables when they do not need dotty context; dotfiles-owned commands can use them for wrappers, compatibility cleanup, and host integration without duplicating manifest metadata.

Install commands may perform tool-specific checks, but they should not clone or update the repo themselves unless the shared sync layer explicitly hands them that responsibility.

## First Implementation Slice

Implement the richer manifest around the existing development checkout flow, then prove it on both checkout-only and installed devtools.

The first slice should:

- Replace or migrate `.dotty/dev-checkouts.tsv` into `.dotty/devtools.tsv` rather than adding a parallel config path.
- Keep checkout-only tools such as `comment-width-check`, `oxlint-config`, and `tmux-agent-bar` in the same manifest with an empty install field.
- Convert Jackie Plan so repo URL, branch, checkout path, and installer dispatch come from the manifest instead of being repeated across the manifest, `scripts/sync-dev-checkouts.sh`, and `.dotty/commands/install-jackie-plan`.
- Convert the GodspeedJS install path so `dotty update` dispatches it through the manifest instead of dedicated `setup_godspeed_js` logic in `.dotty/run.sh`.
- Rename the shared sync implementation and dotty command surface around devtools. Preserve old checkout naming only as a deliberately scoped compatibility wrapper if a real current caller requires it.
- Keep the dotfiles repo, dotty's own repo-chain update flow, and later repos in the dotty chain outside this devtool manifest. Those are the system that applies configuration; this manifest is for external editable devtool checkouts managed by that system.
- Leave runtime-only tools out of the first slice unless the implementation naturally supports them without extra branching. The priority is editable devtool repos that are intended to live under `~/src`.
- Update user-facing and agent-facing documentation in the same change, including the README command table and setup prose, `docs/agent-tooling.md`, relevant `AGENTS.md` mental-model guidance, and manifest comments or examples.

## Migration and Cleanup Expectations

Treat this as a real migration, not a new abstraction around old files. Rename the manifest and command surface to devtools-oriented names, update all repo docs and checks, and remove the old checkout-only config path instead of leaving both active.

On the current machine, run the narrow sync/install path and then `dotty update` so existing declared checkouts, Jackie Plan, GodspeedJS, and any legacy Jackie Plan runtime-checkout state are reconciled through the new manifest-driven flow.

For fresh-machine confidence, tests should cover an empty checkout root cloning declared devtools and dispatching installs from the manifest. If a true personal-machine `dotty update` validation cannot be performed during implementation, leave a checkpoint or follow-up that says exactly what remains to verify there; do not split the implementation just for that.

## Implementation Stopping Points

Implement this as one change. Stop and ask the user only if the manifest design needs per-machine overrides, runtime-only checkout handling, destructive cleanup of a real existing checkout, or a repo-owned installer does not expose a usable command.

Otherwise, make conservative naming and migration choices, complete the docs and tests, run the documented verification, run the local sync/update validation, and hand the completed change back for final review.

## Non-Goals

- Do not build a broad package manager, plugin manager, or hidden orchestrator.
- Do not preserve compatibility paths just because they exist today.
- Do not add YAML or another parser dependency for this manifest.
- Do not make the manifest executable shell code.
- Do not add per-machine override machinery unless the implementation hits a real current need.
- Do not make dotty self-management, dotfiles repo cloning, dotty-chain repo updates, or later-repo orchestration part of this slice.
- Do not route every runtime-only checkout through the devtool model before proving it on editable devtool repos.

## Acceptance Criteria

- A tracked TSV manifest at `.dotty/devtools.tsv` can declare at least Jackie Plan and GodspeedJS as installed devtools and at least one checkout-only devtool.
- The manifest is scoped to external editable devtool checkouts, not the dotfiles repo itself, dotty's own repo-chain update flow, or later repos in the dotty chain.
- `dotty update` and `dotty run sync-devtools` continue to converge declared devtool repos without prompting for Git credentials.
- Missing declared devtool repos are cloned to their configured location.
- Clean declared repos on the configured branch fast-forward when their origin matches the manifest.
- Dirty, branch-mismatched, or origin-mismatched repos are skipped with explicit warnings rather than overwritten.
- Checkout-only devtools do not run install commands.
- Installed devtools dispatch their configured install action after sync without duplicating repo URL, branch, or checkout path in a second script.
- Install actions receive configured metadata through `DOTTY_DEVTOOL_NAME`, `DOTTY_DEVTOOL_CHECKOUT_DIR`, `DOTTY_DEVTOOL_REPO_URL`, and `DOTTY_DEVTOOL_BRANCH`, with no duplicate positional-argument metadata API.
- `repo:` install actions run with the configured checkout as the working directory, and `dotty:` install actions run with the dotfiles repo as the working directory.
- Jackie Plan installation runs from the configured checkout, and any remaining legacy runtime-checkout compatibility behavior is removed or converted into explicit cleanup rather than kept as ongoing install logic.
- GodspeedJS installation is driven by the manifest instead of dedicated `setup_godspeed_js` logic in `.dotty/run.sh`.
- Existing current-machine declared checkouts and installs are reconciled by the new manifest-driven path after running the narrow sync/install command and `dotty update`.
- Fresh-machine behavior is covered by tests that start with an empty checkout root, clone declared devtools, and dispatch manifest installs.
- README setup prose and command tables describe the new manifest and any command-name or file-name changes.
- `docs/agent-tooling.md` explains how to add checkout-only and installed personal devtools, the `DOTTY_DEVTOOL_*` install-action environment contract, and when to use this model versus a runtime-only checkout.
- Relevant `AGENTS.md` mental-model guidance is updated if the source-of-truth boundary, command surface, or dotty-chain routing guidance changes.
- The manifest itself includes enough header comments or examples that adding a new devtool does not require reverse-engineering the parser.
- Focused tests cover manifest parsing, checkout-only tools, installed tools, skipped dirty/customized repos, install dispatch for both repo-owned and dotfiles-owned commands, working-directory selection, and the `DOTTY_DEVTOOL_*` environment contract.

## Readiness Assessment

The plan is still worth doing because the repo already has repeated devtool ceremony: checkout metadata lives in `.dotty/dev-checkouts.tsv`, while installed tools require separate hook functions or command scripts. The contract is ready once the implementation sticks to the TSV manifest and install-dispatch model above. Avoid expanding the slice into a general package manager or runtime checkout framework.

This should be implemented as one shot with final review after validation, not split into separate implementation plans. The plan includes explicit stopping points for cases that would make unsupervised migration risky.

## Agent handoff

Implementation is code-complete and waiting for user review in `/Users/jackokerman/dotfiles`; do not commit, push, mark `ready-to-ship`, or complete without explicit user approval.

Changed implementation shape:
- Renamed `.dotty/dev-checkouts.tsv` to `.dotty/devtools.tsv` with six columns: `name`, `repo-url`, `branch`, `checkout`, `update`, and `install`.
- Replaced `scripts/sync-dev-checkouts.sh` with `scripts/sync-devtools.sh`, preserving conservative non-interactive clone/fetch/fast-forward behavior while adding install dispatch for `repo:` and `dotty:` actions.
- Added `dotty run sync-devtools` and removed the old `sync-dev-checkouts` command surface because no current caller required a compatibility wrapper.
- Removed the dotfiles-owned Jackie Plan installer; Jackie Plan now uses the manifest row `repo:scripts/install.sh` from `~/src/jackie-plan`.
- Added `.dotty/commands/install-godspeed-js` for the manifest row `dotty:.dotty/commands/install-godspeed-js`.
- Routed `.dotty/run.sh` through the single devtools sync/install path instead of separate checkout, Jackie Plan, and GodspeedJS functions.
- Updated `scripts/check`, README, `docs/agent-tooling.md`, and `AGENTS.md` for the new source-of-truth and command surface.
- Expanded tests under `tests/devtools/` for empty-root cloning, checkout-only rows, repo-owned and dotfiles-owned install actions, working-directory selection, `DOTTY_DEVTOOL_*` metadata, malformed rows, non-interactive Git, and conservative dirty/origin mismatch skips.

Verification completed:
- `tests/devtools/test-sync.sh` passed.
- `./scripts/check --extended --quiet` passed. It printed advisory long-paragraph notes for existing docs/README prose, but no failures.
- `dotty run sync-devtools` completed successfully on the current machine: all declared repos were already up to date, GodspeedJS CLIs were linked, Jackie Plan installed through its repo script, and checkout-only tools ran no install actions.
- `dotty update` completed successfully and exercised the new devtools path through the normal base repo hook.

Follow-up captured:
- `2026-07-14-make-jackie-plan-installer-install-only-friendly-for-manifest` tracks out-of-scope Jackie Plan repo work to expose an install-only installer boundary so manifest-driven callers avoid the repo installer's redundant fetch/update.

Remaining review focus:
- Confirm the intentionally removed `dotty run sync-dev-checkouts` and `.dotty/commands/install-jackie-plan` surfaces are acceptable.
- Confirm the policy to skip install actions when checkout sync is skipped for dirty, branch-mismatched, origin-mismatched, or diverged repos is the desired conservative behavior.
