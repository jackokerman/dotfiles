#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_SCRIPT="${PROJECT_ROOT}/scripts/sync-handy-settings.sh"
TEST_PREFIX="handy-sync-test"
MANAGED_PROMPT_ID="dotfiles_improve_transcriptions"
MANAGED_PROMPT_NAME="Improve Transcriptions (Dotfiles)"

# shellcheck source=/dev/null
source "${PROJECT_ROOT}/tests/tmux-agent-status/testlib.sh"

run_sync() {
    local prompt_path="$1" settings_path="$2"

    HANDY_PROMPT_SOURCE="${prompt_path}" \
        HANDY_SETTINGS_PATH="${settings_path}" \
        HANDY_SKIP_RUNNING_CHECK=1 \
        "${TARGET_SCRIPT}"
}

write_prompt_file() {
    local path="$1"

    cat >"${path}" <<'EOF'
Clean this transcript.

Keep the exact meaning and remove obvious filler.

Transcript:
${output}
EOF
}

write_settings_without_managed_prompt() {
    local path="$1"

    cat >"${path}" <<'EOF'
{
  "settings": {
    "selected_model": "parakeet-tdt-0.6b-v3",
    "post_process_selected_prompt_id": "default_improve_transcriptions",
    "post_process_prompts": [
      {
        "id": "default_improve_transcriptions",
        "name": "Improve Transcriptions",
        "prompt": "Default prompt"
      }
    ]
  }
}
EOF
}

write_settings_with_managed_prompt() {
    local path="$1"

    cat >"${path}" <<'EOF'
{
  "settings": {
    "selected_model": "parakeet-tdt-0.6b-v3",
    "post_process_selected_prompt_id": "default_improve_transcriptions",
    "post_process_prompts": [
      {
        "id": "default_improve_transcriptions",
        "name": "Improve Transcriptions",
        "prompt": "Default prompt"
      },
      {
        "id": "dotfiles_improve_transcriptions",
        "name": "Old managed prompt",
        "prompt": "Old prompt body"
      }
    ]
  }
}
EOF
}

assert_prompt_value() {
    local name="$1" settings_path="$2" expected="$3"
    local actual=""

    actual="$(jq -r --arg id "${MANAGED_PROMPT_ID}" '.settings.post_process_prompts[] | select(.id == $id) | .prompt' "${settings_path}")"
    assert_equal "${name}" "${expected}" "${actual}"
}

test_skips_when_settings_file_is_missing() {
    local tmp_dir="" prompt_path="" settings_path=""

    tmp_dir="$(mktemp -d)"
    prompt_path="${tmp_dir}/prompt.txt"
    settings_path="${tmp_dir}/settings_store.json"

    write_prompt_file "${prompt_path}"
    run_sync "${prompt_path}" "${settings_path}"

    if [[ -e "${settings_path}" ]]; then
        fail "missing settings file should not be created"
    fi

    pass "missing settings file is skipped"
    rm -rf "${tmp_dir}"
}

test_adds_managed_prompt_and_preserves_existing_state() {
    local tmp_dir="" prompt_path="" settings_path="" prompt_contents="" has_default=""

    tmp_dir="$(mktemp -d)"
    prompt_path="${tmp_dir}/prompt.txt"
    settings_path="${tmp_dir}/settings_store.json"

    write_prompt_file "${prompt_path}"
    write_settings_without_managed_prompt "${settings_path}"
    prompt_contents="$(<"${prompt_path}")"

    run_sync "${prompt_path}" "${settings_path}"

    assert_equal \
        "managed prompt becomes selected" \
        "${MANAGED_PROMPT_ID}" \
        "$(jq -r '.settings.post_process_selected_prompt_id' "${settings_path}")"
    assert_equal \
        "selected model is preserved" \
        "parakeet-tdt-0.6b-v3" \
        "$(jq -r '.settings.selected_model' "${settings_path}")"
    assert_equal \
        "managed prompt is added once" \
        "2" \
        "$(jq -r '.settings.post_process_prompts | length' "${settings_path}")"
    assert_equal \
        "managed prompt name is tracked" \
        "${MANAGED_PROMPT_NAME}" \
        "$(jq -r --arg id "${MANAGED_PROMPT_ID}" '.settings.post_process_prompts[] | select(.id == $id) | .name' "${settings_path}")"
    assert_prompt_value "managed prompt body is copied exactly" "${settings_path}" "${prompt_contents}"

    has_default="$(jq -r 'any(.settings.post_process_prompts[]; .id == "default_improve_transcriptions")' "${settings_path}")"
    assert_equal "default prompt is preserved" "true" "${has_default}"

    rm -rf "${tmp_dir}"
}

test_updates_existing_managed_prompt_without_duplication() {
    local tmp_dir="" prompt_path="" settings_path="" prompt_contents=""

    tmp_dir="$(mktemp -d)"
    prompt_path="${tmp_dir}/prompt.txt"
    settings_path="${tmp_dir}/settings_store.json"

    write_prompt_file "${prompt_path}"
    write_settings_with_managed_prompt "${settings_path}"
    prompt_contents="$(<"${prompt_path}")"

    run_sync "${prompt_path}" "${settings_path}"

    assert_equal \
        "managed prompt stays unique" \
        "1" \
        "$(jq -r --arg id "${MANAGED_PROMPT_ID}" '[.settings.post_process_prompts[] | select(.id == $id)] | length' "${settings_path}")"
    assert_equal \
        "managed prompt stays selected" \
        "${MANAGED_PROMPT_ID}" \
        "$(jq -r '.settings.post_process_selected_prompt_id' "${settings_path}")"
    assert_prompt_value "managed prompt body is updated" "${settings_path}" "${prompt_contents}"

    rm -rf "${tmp_dir}"
}

test_fails_for_invalid_settings_shape() {
    local tmp_dir="" prompt_path="" settings_path=""

    tmp_dir="$(mktemp -d)"
    prompt_path="${tmp_dir}/prompt.txt"
    settings_path="${tmp_dir}/settings_store.json"

    write_prompt_file "${prompt_path}"
    printf '{}\n' >"${settings_path}"

    if run_sync "${prompt_path}" "${settings_path}" >/dev/null 2>&1; then
        fail "invalid settings shape should fail"
    fi

    pass "invalid settings shape fails"
    rm -rf "${tmp_dir}"
}

test_skips_when_already_in_sync() {
    local tmp_dir="" prompt_path="" settings_path="" before_hash="" after_hash=""

    tmp_dir="$(mktemp -d)"
    prompt_path="${tmp_dir}/prompt.txt"
    settings_path="${tmp_dir}/settings_store.json"

    write_prompt_file "${prompt_path}"
    write_settings_with_managed_prompt "${settings_path}"

    run_sync "${prompt_path}" "${settings_path}"
    before_hash="$(shasum -a 256 "${settings_path}" | awk '{print $1}')"

    run_sync "${prompt_path}" "${settings_path}"
    after_hash="$(shasum -a 256 "${settings_path}" | awk '{print $1}')"

    assert_equal "sync is idempotent" "${before_hash}" "${after_hash}"

    rm -rf "${tmp_dir}"
}

test_skips_when_settings_file_is_missing
test_adds_managed_prompt_and_preserves_existing_state
test_updates_existing_managed_prompt_without_duplication
test_fails_for_invalid_settings_shape
test_skips_when_already_in_sync
