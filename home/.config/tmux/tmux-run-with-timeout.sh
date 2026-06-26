#!/usr/bin/env bash
set -euo pipefail

_timeout_seconds="${1:-}"
shift || true

if [[ -z "${_timeout_seconds}" || "$#" -eq 0 ]]; then
  echo "usage: ${0##*/} <seconds> <command> [args...]" >&2
  exit 2
fi

if command -v timeout >/dev/null 2>&1; then
  exec timeout "${_timeout_seconds}" "$@"
fi

if command -v gtimeout >/dev/null 2>&1; then
  exec gtimeout "${_timeout_seconds}" "$@"
fi

if command -v python3 >/dev/null 2>&1; then
  exec python3 - "${_timeout_seconds}" "$@" <<'PY'
import os
import signal
import subprocess
import sys

timeout_seconds = float(sys.argv[1])
command = sys.argv[2:]
process = subprocess.Popen(command, start_new_session=True)

try:
    sys.exit(process.wait(timeout=timeout_seconds))
except subprocess.TimeoutExpired:
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        sys.exit(124)

    try:
        process.wait(timeout=0.2)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait()

    sys.exit(124)
PY
fi

exec "$@"
