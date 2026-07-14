# Scripts

TypeScript maintenance scripts live in `scripts/ts/` and intentionally use Bun's script dependency resolution instead of a root package manifest or `scripts.json`.

After changing `scripts/ts/*.ts`, stage the intended files and run:

```sh
./scripts/check --staged --quiet
```

The staged check runs the pinned `bunx` TypeScript tooling stack for `scripts/ts`: Oxlint with warnings denied, shared Oxfmt config drift checks, Oxfmt format checks, `comment-width-check`, and blocking `slop-scan`.
