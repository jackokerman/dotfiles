# Scripts

This directory keeps stable shell entrypoints at the top level. Repo-maintenance TypeScript scripts live in `scripts/ts/` and share the root `package.json` and `bun.lock` dependencies.

Use these conventions for new helpers:

- Put repo-maintenance TypeScript in `scripts/ts/`.
- Put substantive reusable shell workflow logic in `scripts/`, and keep `.dotty/commands/*` as thin `dotty run` entrypoints that dispatch here.
- Put installed CLI implementations in `home/.local/lib/` with a wrapper in `home/.local/bin/`.
- Keep feature tests under `tests/<feature>/`.
- Wire the narrow staged check and full-suite check in `scripts/check`.
