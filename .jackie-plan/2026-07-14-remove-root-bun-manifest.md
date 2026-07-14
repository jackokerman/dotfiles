---
id: 2026-07-14-remove-root-bun-manifest
title: Remove root Bun manifest
state: complete
createdAt: 2026-07-14T06:00:03.722Z
updatedAt: 2026-07-14T06:04:28.636Z
---

# Remove root Bun manifest

## Plan

Remove the root `package.json` and `bun.lock` from dotfiles by converting repo-owned TypeScript scripts and tests to run with Bun's script dependency resolution instead of shared root dependencies.

Scope:

- audit every current root dependency consumer before deleting the manifest;
- convert TypeScript entrypoints and tests that need third-party packages to declare or resolve those dependencies at the script boundary;
- update shell runners that currently assume root `bun install --cwd` or shared root dependencies;
- update docs and repo steering that mention the shared root manifest;
- remove generated dependency artifacts such as `bun.lock` and any obsolete root install step.

Non-goals:

- do not change external project toolchains such as `godspeed-js`;
- do not add a new package manager, wrapper framework, or alternate dependency manifest;
- do not rewrite unrelated shell helpers.

Verification:

- run the narrow script/test commands touched by the migration;
- run `./scripts/check --quiet`;
- run `dotty update` before finishing so live generated config reflects the tracked repo state.

The implementation can proceed immediately after capture because the desired direction is explicit and the change should be mechanically verifiable.

## Agent handoff

Implemented immediately after capture with user approval.

Changes made:

- Removed root `package.json` and `bun.lock`.
- Removed the dotty hook's root `bun install --cwd "$DOTFILES" --frozen-lockfile` step.
- Changed repo-owned TypeScript scripts and wrappers to run with `bun --install=fallback`.
- Pinned third-party script dependencies directly in import specifiers:
  - `es-toolkit@1.45.1`
  - `karabiner.ts@1.37.0`
  - `marked@18.0.3`
  - `plist@3.1.0`
  - `smol-toml@1.4.2`
  - `yaml@2.8.1`
- Updated docs and tests that referenced root Bun dependencies.

Verification passed before commit:

- `bun --install=fallback test tests/karabiner/karabiner-config.test.ts`
- `bun --install=fallback test tests/codex/sync-codex.test.ts tests/codex/sync-ruler.test.ts`
- `bun --install=fallback test tests/slack-rich-text/slack-rich-text.test.ts`
- `./scripts/check --quiet`
