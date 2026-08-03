#!/usr/bin/env bash
set -euo pipefail

readonly CODEX_CONFIG="${HOME}/.codex/config.toml"

[[ -f "${CODEX_CONFIG}" ]] || exit 0

if ! grep -Eq '^(apps|suppress_unstable_features_warning)[[:space:]]*=' "${CODEX_CONFIG}"; then
    exit 0
fi

if [[ "${DOTTY_DRY_RUN:-false}" == "true" ]]; then
    printf '[dry-run] Would remove stale Codex feature overrides from %s\n' "${CODEX_CONFIG}"
    exit 0
fi

TEMP_CONFIG="$(mktemp "${CODEX_CONFIG}.cleanup.XXXXXX")"
trap 'rm -f "${TEMP_CONFIG}"' EXIT

awk '
    /^\[/ {
        in_features = ($0 == "[features]")
    }
    /^suppress_unstable_features_warning[[:space:]]*=/ {
        next
    }
    in_features && /^apps[[:space:]]*=/ {
        next
    }
    { print }
' "${CODEX_CONFIG}" > "${TEMP_CONFIG}"

cp "${TEMP_CONFIG}" "${CODEX_CONFIG}"
printf 'Removed stale Codex feature overrides from %s\n' "${CODEX_CONFIG}"
