---
name: shared-config-rollout
description: Roll out releases of shared personal packages, config packages, lint/style configs, Raycast clients, Codex skills/config, or other reusable tooling to downstream local repositories. Use when Codex releases or updates a shared package and should find dependents, bump dependency versions, run lint/checks, apply required style or API fallout fixes, commit, and push the downstream updates.
---

# Shared Config Rollout

Keep shared tooling generic at the source, then update its dependents explicitly. Do not put downstream repo names, environment-specific setup, or local rollout policy into the shared package's README, config, `AGENTS.md`, or lint guidance unless that package actually owns those details.

## Workflow

1. Verify the source update is real.
   - Confirm the release, tag, registry version, or local package artifact that dependents should consume.
   - Classify the release impact before touching dependents. Roll out downstream dependency bumps for exported config, runtime, API, or generated-output behavior changes. Do not churn dependents for docs-only, README-only, release-metadata, or source-repo check-tooling changes unless the user explicitly asks.
   - If the source package is dotty-managed config or generated Codex output, update tracked sources first and run `dotty update` before rolling it out.

2. Discover downstream dependents.
   - Start with local checkouts and narrow package identifiers:
     `rg '<package-or-config-name>' ~/src -g 'package.json' -g 'bun.lock' -g 'pnpm-lock.yaml' -g 'yarn.lock' -g 'package-lock.json' -g '*.config.*'`
   - Include user-specified roots before broadening the search.
   - Prefer local checkouts over remote code search. Use authenticated GitHub search only when local repos are missing or stale.

3. Update each dependent repo separately.
   - Read its `AGENTS.md` or local contributor instructions first.
   - Check `git status --short --branch`; do not mix unrelated dirty work into the rollout.
   - Use the repo's package manager to bump the dependency and lockfile.
   - Run the smallest relevant verification first, usually lint, then the repo's full check if the dependency changes behavior.
   - Fix only fallout caused by the new shared package version. Let strict configs improve code, but keep edits scoped.

4. Commit and push according to each dependent repo's workflow.
   - Use conventional commits.
   - For dotty-managed repos, run `dotty update` after tracked config or skill changes and finish with commit and push to `main`.
   - For laptop dotfiles repos, use `gpush` instead of raw `git push`.
   - If a dependent repo requires PRs or branch workflows, follow its local instructions instead of pushing directly.

5. Report the rollout state.
   - List the source version released or consumed.
   - List each dependent updated, verification run, commit pushed, and any repo skipped. If the release was not rolled out because it did not affect consumers, say that explicitly.
   - If auth, CI, or package registry setup blocks rollout, state the exact blocker and the next action needed from the user.

## Boundaries

- Keep shared package docs and config work-agnostic unless the package itself is intentionally specific to one environment.
- Keep personal rollout knowledge in personal dotfiles skills or scripts, not in downstream package guidance.
- Keep environment-specific rollout knowledge in the later config layer that owns it.
- Do not create permanent repo manifests unless the user asks; a local discovery pass is enough for normal rollouts.
