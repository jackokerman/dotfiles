#!/usr/bin/env bash

tmux_agent_capture_tail() {
  local session="$1" lines="${2:-20}"
  tmux capture-pane -pt "${session}" 2>/dev/null | tail -n "${lines}" || true
}

tmux_codex_infer_state_from_tail() {
  local tail="$1"

  case "${tail}" in
    *"Do you want me to "*|*"Messages to be submitted after next tool call"*|*"Would you like to run the following command?"*|*"Press enter to confirm or esc to cancel"*|*"permission prompt"*|*"approval"*|*"tab to add notes"*|*"enter to submit answer"*|*"Implement this plan?"*|*"Yes, implement this plan"*|*"No, stay in Plan mode"*)
      printf '%s\n' "waiting"
      return 0
      ;;
  esac

  if [[ "${tail}" == *"Question "* && "${tail}" == *"unanswered"* ]]; then
    printf '%s\n' "waiting"
    return 0
  fi

  case "${tail}" in
    *"• Working ("*|*"esc to interrupt"*)
      printf '%s\n' "working"
      return 0
      ;;
  esac

  printf '%s\n' ""
}

tmux_agent_infer_state_from_tail() {
  local agent="$1" tail="$2"

  case "${agent}" in
    codex)
      tmux_codex_infer_state_from_tail "${tail}"
      ;;
    claude)
      case "${tail}" in
        *"Do you want me to "*|*"Messages to be submitted after next tool call"*|*"Would you like to run the following command?"*|*"Press enter to confirm or esc to cancel"*|*"permission prompt"*|*"approval"*)
          printf '%s\n' "waiting"
          return 0
          ;;
        *"• Working ("*|*"esc to interrupt"*)
          printf '%s\n' "working"
          return 0
          ;;
      esac
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
