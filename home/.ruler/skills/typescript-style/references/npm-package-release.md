# npm Package Release Checklist

Use this reference when creating or publishing a reusable npm package, especially with `semantic-release`, GitHub Actions, or npm Trusted Publishing.

## Before First Publish

- Verify whether the package already exists with `npm view <package> version` or `bun pm view <package> version`.
- For a new scoped package, remember that npm Trusted Publishing is configured from package settings after the package exists. Plan one initial authenticated publish before switching to OIDC.
- Prefer a temporary granular npm token for the first publish. If the account requires 2FA for writes, the CI publish token must be allowed to bypass 2FA; otherwise `npm publish` fails with `EOTP`.
- Scope the temporary token as narrowly as npm allows, use a short expiration, store it only as a GitHub Actions secret, and revoke it immediately after the first successful publish.
- Confirm the release workflow has the necessary GitHub permissions before running it: `contents: write` for release commits/tags and `id-token: write` for provenance or Trusted Publishing.

## Publish And Verify

- Keep public package READMEs consumer-focused: what the package is, how to install it, and how to use it. Avoid encoding internal origin stories, local project names, change history, or exhaustive generated-rule summaries that will drift from source.
- For public packages, run `public-content-guard --worktree` when it is available before publishing docs or package metadata changes. Keep host-specific pattern files outside public repos.
- Make the initial release workflow manual until npm auth and package visibility are confirmed.
- After a release run, verify both the workflow logs and the registry. npm can report a successful publish before package metadata is visible through the top-level package endpoint.
- Check the exact version endpoint if top-level metadata lags: `https://registry.npmjs.org/<encoded-package>/<version>`.
- Treat `npm publish` errors carefully:
  - `EOTP` means the token cannot bypass write-time 2FA.
  - `previously published versions` means the version exists even if metadata lookup is stale.
  - `404` from `npm view` can mean missing package, private/inaccessible package, or delayed metadata visibility; cross-check package access and exact version metadata before republishing.

## After First Publish

- Remove temporary token usage from the workflow and delete the GitHub Actions secret.
- Ask the user to revoke the npm token in npm account settings; deleting the GitHub secret does not revoke the npm-issued token.
- Configure npm Trusted Publishing for the package, pointing at the exact GitHub repository and workflow filename. Leave the environment blank unless the workflow actually uses a GitHub environment.
- Update dependents from GitHub refs to the published npm version, then run the dependent repo's normal checks before committing.
