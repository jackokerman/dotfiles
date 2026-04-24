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

run_sync_with_fake_handy() {
    local prompt_path="$1" settings_path="$2" fake_bin_dir="$3" state_dir="$4"

    PATH="${fake_bin_dir}:$PATH" \
        HANDY_PROMPT_SOURCE="${prompt_path}" \
        HANDY_SETTINGS_PATH="${settings_path}" \
        HANDY_TEST_STATE_DIR="${state_dir}" \
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

write_fake_handy_commands() {
    local fake_bin_dir="$1"

    mkdir -p "${fake_bin_dir}"

    cat >"${fake_bin_dir}/pgrep" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ -f "${HANDY_TEST_STATE_DIR}/handy-running" ]]; then
    exit 0
fi

exit 1
EOF

    cat >"${fake_bin_dir}/osascript" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

touch "${HANDY_TEST_STATE_DIR}/quit-called"
rm -f "${HANDY_TEST_STATE_DIR}/handy-running"
EOF

    cat >"${fake_bin_dir}/open" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

touch "${HANDY_TEST_STATE_DIR}/open-called"
touch "${HANDY_TEST_STATE_DIR}/handy-running"
EOF

    chmod +x "${fake_bin_dir}/pgrep" "${fake_bin_dir}/osascript" "${fake_bin_dir}/open"
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

test_restarts_handy_when_managed_prompt_changes() {
    local tmp_dir="" prompt_path="" settings_path="" fake_bin_dir="" state_dir=""

    tmp_dir="$(mktemp -d)"
    prompt_path="${tmp_dir}/prompt.txt"
    settings_path="${tmp_dir}/settings_store.json"
    fake_bin_dir="${tmp_dir}/bin"
    state_dir="${tmp_dir}/state"

    mkdir -p "${state_dir}"
    touch "${state_dir}/handy-running"

    write_prompt_file "${prompt_path}"
    write_settings_without_managed_prompt "${settings_path}"
    write_fake_handy_commands "${fake_bin_dir}"

    run_sync_with_fake_handy "${prompt_path}" "${settings_path}" "${fake_bin_dir}" "${state_dir}"

    assert_equal \
        "restart path selects the managed prompt" \
        "${MANAGED_PROMPT_ID}" \
        "$(jq -r '.settings.post_process_selected_prompt_id' "${settings_path}")"
    assert_equal \
        "restart path quits Handy before syncing" \
        "true" \
        "$([[ -f "${state_dir}/quit-called" ]] && echo true || echo false)"
    assert_equal \
        "restart path relaunches Handy after syncing" \
        "true" \
        "$([[ -f "${state_dir}/open-called" ]] && echo true || echo false)"

    rm -rf "${tmp_dir}"
}

test_does_not_restart_handy_when_prompt_is_already_in_sync() {
    local tmp_dir="" prompt_path="" settings_path="" fake_bin_dir="" state_dir=""

    tmp_dir="$(mktemp -d)"
    prompt_path="${tmp_dir}/prompt.txt"
    settings_path="${tmp_dir}/settings_store.json"
    fake_bin_dir="${tmp_dir}/bin"
    state_dir="${tmp_dir}/state"

    mkdir -p "${state_dir}"
    touch "${state_dir}/handy-running"

    write_prompt_file "${prompt_path}"
    write_settings_with_managed_prompt "${settings_path}"
    run_sync "${prompt_path}" "${settings_path}"
    write_fake_handy_commands "${fake_bin_dir}"

    run_sync_with_fake_handy "${prompt_path}" "${settings_path}" "${fake_bin_dir}" "${state_dir}"

    assert_equal \
        "already-synced prompt does not quit Handy" \
        "false" \
        "$([[ -f "${state_dir}/quit-called" ]] && echo true || echo false)"
    assert_equal \
        "already-synced prompt does not relaunch Handy" \
        "false" \
        "$([[ -f "${state_dir}/open-called" ]] && echo true || echo false)"

    rm -rf "${tmp_dir}"
}

test_skips_when_settings_file_is_missing
test_adds_managed_prompt_and_preserves_existing_state
test_updates_existing_managed_prompt_without_duplication
test_fails_for_invalid_settings_shape
test_skips_when_already_in_sync
test_restarts_handy_when_managed_prompt_changes
test_does_not_restart_handy_when_prompt_is_already_in_sync
