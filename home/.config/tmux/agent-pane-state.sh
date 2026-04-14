#!/usr/bin/env bash

tmux_agent_capture_tail() {
  local session="$1" lines="${2:-40}"
  tmux capture-pane -pt "${session}" 2>/dev/null | tail -n "${lines}" || true
}

tmux_agent_reverse_lines() {
  awk '{ lines[NR] = $0 } END { for (i = NR; i >= 1; i--) print lines[i] }'
}

tmux_agent_line_is_waiting() {
  local line="$1"

  case "${line}" in
    *"Do you want me to "*|*"Messages to be submitted after next tool call"*|*"Would you like to run the following command?"*|*"Press enter to confirm or esc to cancel"*|*"permission prompt"*|*"approval"*|*"tab to add notes"*|*"enter to submit answer"*|*"Implement this plan?"*|*"Yes, implement this plan"*|*"No, stay in Plan mode"*)
      return 0
      ;;
  esac

  [[ "${line}" == *"Question "* && "${line}" == *"unanswered"* ]]
}

tmux_agent_line_is_working() {
  local line="$1"

  case "${line}" in
    *"• Working ("*|*"esc to interrupt"*)
      return 0
      ;;
  esac

  return 1
}

tmux_agent_state_file_mtime() {
  local state_file="$1"

  if stat -f '%m' "${state_file}" >/dev/null 2>&1; then
    stat -f '%m' "${state_file}"
    return 0
  fi

  stat -c '%Y' "${state_file}"
}

tmux_agent_state_is_stale_working() {
  local state_file="$1" ttl="${2:-${TMUX_AGENT_WORKING_TTL:-20}}" mtime="" now=""

  [[ -f "${state_file}" ]] || return 1

  mtime=$(tmux_agent_state_file_mtime "${state_file}" 2>/dev/null || true)
  [[ "${mtime}" =~ ^[0-9]+$ ]] || return 1

  now=$(date +%s)
  (( now - mtime > ttl ))
}

tmux_codex_infer_state_from_tail() {
  local tail="$1" line=""

  while IFS= read -r line; do
    if tmux_agent_line_is_working "${line}"; then
      printf '%s\n' "working"
      return 0
    fi

    if tmux_agent_line_is_waiting "${line}"; then
      printf '%s\n' "waiting"
      return 0
    fi
  done < <(printf '%s\n' "${tail}" | tmux_agent_reverse_lines)

  printf '%s\n' ""
}

tmux_agent_infer_state_from_tail() {
  local agent="$1" tail="$2"

  case "${agent}" in
    codex)
      tmux_codex_infer_state_from_tail "${tail}"
      ;;
    claude)
      while IFS= read -r line; do
        if tmux_agent_line_is_working "${line}"; then
          printf '%s\n' "working"
          return 0
        fi

        if tmux_agent_line_is_waiting "${line}"; then
          printf '%s\n' "waiting"
          return 0
        fi
      done < <(printf '%s\n' "${tail}" | tmux_agent_reverse_lines)

      printf '%s\n' ""
      ;;
    *)
      printf '%s\n' ""
      ;;
  esac
}

tmux_agent_session_live_state() {
  local session="$1" agent="$2" tail=""

  [[ -n "${agent}" ]] || {
    printf '%s\n' ""
    return 0
  }

  tail=$(tmux_agent_capture_tail "${session}")
  tmux_agent_infer_state_from_tail "${agent}" "${tail}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  case "${1:-}" in
    infer-session)
      tmux_agent_session_live_state "${2:-}" "${3:-}"
      ;;
    infer-tail)
      agent="${2:-}"
      tail=$(cat)
      tmux_agent_infer_state_from_tail "${agent}" "${tail}"
      ;;
    *)
      echo "usage: ${0##*/} <infer-session session agent|infer-tail agent>" >&2
      exit 2
      ;;
  esac
fi
