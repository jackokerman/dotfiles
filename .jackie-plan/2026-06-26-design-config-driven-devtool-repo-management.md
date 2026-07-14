---
id: 2026-06-26-design-config-driven-devtool-repo-management
title: Design config-driven devtool repo management
state: ready-to-implement
createdAt: 2026-06-26T17:42:12.482Z
updatedAt: 2026-07-14T16:50:18.630Z
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

- Replace or migrate `.dotty/dev-checkouts.tsv` into the richer TSV manifest rather than adding a parallel config path.
- Keep checkout-only tools such as `comment-width-check`, `oxlint-config`, and `tmux-agent-bar` in the same manifest with an empty install field.
- Convert Jackie Plan so repo URL, branch, checkout path, and installer dispatch come from the manifest instead of being repeated across the manifest, `scripts/sync-dev-checkouts.sh`, and `.dotty/commands/install-jackie-plan`.
- Convert the GodspeedJS install path so `dotty update` dispatches it through the manifest instead of dedicated `setup_godspeed_js` logic in `.dotty/run.sh`.
- Leave runtime-only tools out of the first slice unless the implementation naturally supports them without extra branching. The priority is editable devtool repos that are intended to live under `~/src`.

## Non-Goals

- Do not build a broad package manager, plugin manager, or hidden orchestrator.
- Do not preserve compatibility paths just because they exist today.
- Do not add YAML or another parser dependency for this manifest.
- Do not make the manifest executable shell code.
- Do not add per-machine override machinery unless the implementation hits a real current need.
- Do not make dotty self-management part of this slice.
- Do not route every runtime-only checkout through the devtool model before proving it on editable devtool repos.

## Acceptance Criteria

- A tracked TSV manifest can declare at least Jackie Plan and GodspeedJS as installed devtools and at least one checkout-only devtool.
- `dotty update` and `dotty run sync-dev-checkouts` continue to converge declared devtool repos without prompting for Git credentials.
- Missing declared devtool repos are cloned to their configured location.
- Clean declared repos on the configured branch fast-forward when their origin matches the manifest.
- Dirty, branch-mismatched, or origin-mismatched repos are skipped with explicit warnings rather than overwritten.
- Checkout-only devtools do not run install commands.
- Installed devtools dispatch their configured install action after sync without duplicating repo URL, branch, or checkout path in a second script.
- Install actions receive configured metadata through `DOTTY_DEVTOOL_NAME`, `DOTTY_DEVTOOL_CHECKOUT_DIR`, `DOTTY_DEVTOOL_REPO_URL`, and `DOTTY_DEVTOOL_BRANCH`, with no duplicate positional-argument metadata API.
- `repo:` install actions run with the configured checkout as the working directory, and `dotty:` install actions run with the dotfiles repo as the working directory.
- Jackie Plan installation runs from the configured checkout, and any remaining legacy runtime-checkout compatibility behavior is removed or converted into explicit cleanup rather than kept as ongoing install logic.
- GodspeedJS installation is driven by the manifest instead of dedicated `setup_godspeed_js` logic in `.dotty/run.sh`.
- Docs explain the new manifest, how to add a checkout-only or installed personal devtool, the `DOTTY_DEVTOOL_*` install-action environment contract, and when to use this model versus a runtime-only checkout.
- Focused tests cover manifest parsing, checkout-only tools, installed tools, skipped dirty/customized repos, install dispatch for both repo-owned and dotfiles-owned commands, working-directory selection, and the `DOTTY_DEVTOOL_*` environment contract.

## Readiness Assessment

The plan is still worth doing because the repo already has repeated devtool ceremony: checkout metadata lives in `.dotty/dev-checkouts.tsv`, while installed tools require separate hook functions or command scripts. The contract is ready once the implementation sticks to the TSV manifest and install-dispatch model above. Avoid expanding the slice into a general package manager or runtime checkout framework.

## Agent handoff

Refined install-dispatch metadata passing after user approved env vars over positional arguments. The plan now requires install actions to receive metadata through `DOTTY_DEVTOOL_NAME`, `DOTTY_DEVTOOL_CHECKOUT_DIR`, `DOTTY_DEVTOOL_REPO_URL`, and `DOTTY_DEVTOOL_BRANCH`. It also specifies that `repo:` actions run with the checkout as cwd, `dotty:` actions run with the dotfiles repo as cwd, and the implementation should not add a duplicate positional-argument metadata API.

Process notes
- User asked only to update the plan; do not infer approval to implement, commit, push, or change lifecycle state.
