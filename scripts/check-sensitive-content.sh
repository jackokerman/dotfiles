#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"

cd "$REPO_ROOT"
exec dotty guard-check --staged --exclude ".githooks/sensitive-content-patterns"
