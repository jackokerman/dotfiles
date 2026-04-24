#!/usr/bin/env bash

pass() {
  printf '[%s] pass: %s\n' "${TEST_PREFIX:-tmux-test}" "$1"
}

fail() {
  printf '[%s] fail: %s\n' "${TEST_PREFIX:-tmux-test}" "$1" >&2
  exit 1
}

assert_equal() {
  local name="$1" expected="$2" actual="$3"

  if [[ "${actual}" == "${expected}" ]]; then
    pass "${name}"
    return 0
  fi

  printf '[%s] fail: %s\n' "${TEST_PREFIX:-tmux-test}" "${name}" >&2
  printf '[%s] expected: %q\n' "${TEST_PREFIX:-tmux-test}" "${expected}" >&2
  printf '[%s] actual: %q\n' "${TEST_PREFIX:-tmux-test}" "${actual}" >&2
  exit 1
}
