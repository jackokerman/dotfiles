#!/usr/bin/env bash
set -euo pipefail

printf 'dotty\t%s\t%s\t%s\t%s\t%s\n' \
  "$PWD" \
  "${DOTTY_DEVTOOL_NAME:-}" \
  "${DOTTY_DEVTOOL_CHECKOUT_DIR:-}" \
  "${DOTTY_DEVTOOL_REPO_URL:-}" \
  "${DOTTY_DEVTOOL_BRANCH:-}" \
  >> "${TEST_INSTALL_LOG:?TEST_INSTALL_LOG is required}"
