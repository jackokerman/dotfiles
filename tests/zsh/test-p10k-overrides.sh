#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_P10K="${PROJECT_ROOT}/home/.config/zsh/.p10k.zsh"

fail() {
  printf '[p10k-test] %s\n' "$*" >&2
  exit 1
}

assert_equals() {
  local label="$1"
  local expected="$2"
  local actual="$3"

  if [[ "${actual}" == "${expected}" ]]; then
    printf '[p10k-test] ok: %s\n' "${label}"
  else
    fail "${label} (expected '${expected}', got '${actual}')"
  fi
}

run_zsh_case() {
  local mode="$1"

  zsh -fc '
    case "$1" in
      default)
        source "$2"
        ;;
      override)
        typeset -ga DOTFILES_P10K_LEFT_PROMPT_ELEMENTS_OVERRIDE=(
          dir
          custom_branch
          custom_status
          command_execution_time
          newline
          prompt_char
        )
        typeset -g DOTFILES_P10K_DISABLE_GITSTATUS=true
        source "$2"
        ;;
      *)
        return 2
        ;;
    esac

    print -r -- "${(j: :)POWERLEVEL9K_LEFT_PROMPT_ELEMENTS}"
    print -r -- "${POWERLEVEL9K_DISABLE_GITSTATUS-}"
  ' zsh "${mode}" "${TARGET_P10K}"
}

default_case="$(run_zsh_case default)"
default_left_prompt="$(printf '%s\n' "${default_case}" | sed -n '1p')"
default_gitstatus_disabled="$(printf '%s\n' "${default_case}" | sed -n '2p')"
assert_equals \
  "default left prompt keeps base vcs segment" \
  "dir vcs command_execution_time newline prompt_char" \
  "${default_left_prompt}"
assert_equals "default gitstatus stays enabled" "" "${default_gitstatus_disabled}"

override_case="$(run_zsh_case override)"
override_left_prompt="$(printf '%s\n' "${override_case}" | sed -n '1p')"
override_gitstatus_disabled="$(printf '%s\n' "${override_case}" | sed -n '2p')"
assert_equals \
  "override replaces left prompt elements before p10k config" \
  "dir custom_branch custom_status command_execution_time newline prompt_char" \
  "${override_left_prompt}"
assert_equals "override can disable gitstatus before p10k config" "true" "${override_gitstatus_disabled}"
