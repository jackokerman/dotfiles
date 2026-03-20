#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Restart Chrome
# @raycast.mode compact
# @raycast.icon 🔄
# @raycast.packageName Window Manager

# Restart Chrome and restore window workspace assignments.
# Saves current positions, triggers chrome://restart, waits for windows
# to reappear with stable titles, then moves them back.
set -euo pipefail

get_chrome_windows() {
  local -A chrome_apps
  chrome_apps["Google Chrome"]=1
  local app_dir="$HOME/Applications/Chrome Apps.localized"
  if [[ -d "${app_dir}" ]]; then
    local app
    for app in "${app_dir}"/*.app; do
      [[ -e "${app}" ]] || continue
      chrome_apps["$(basename "${app}" .app)"]=1
    done
  fi

  while IFS='|' read -r wid app_name workspace title; do
    if [[ -n "${chrome_apps["${app_name}"]:-}" ]]; then
      printf '%s|%s|%s|%s\n' "${wid}" "${workspace}" "${app_name}" "${title}"
    fi
  done < <(aerospace list-windows --all --format '%{window-id}|%{app-name}|%{workspace}|%{window-title}')
}

extract_profile() {
  if [[ "$1" == *" - Google Chrome - "* ]]; then
    printf '%s' "${1##* - Google Chrome - }"
  fi
}

extract_tab_title() {
  if [[ "$1" == *" - Google Chrome"* ]]; then
    printf '%s' "${1%% - Google Chrome*}"
  else
    printf '%s' "$1"
  fi
}

word_overlap() {
  local a="$1" b="$2"
  local -i count=0
  local word
  for word in ${a}; do
    if [[ "${b}" == *"${word}"* && ${#word} -gt 2 ]]; then
      (( ++count ))
    fi
  done
  printf '%d' "${count}"
}

original_workspace=$(aerospace list-workspaces --focused)

windows=$(get_chrome_windows)
if [[ -z "${windows}" ]]; then
  echo "No Chrome windows found" >&2
  exit 1
fi

# Save current state into arrays
saved_workspaces=()
saved_app_names=()
saved_titles=()
saved_profiles=()

while IFS='|' read -r wid workspace app_name title; do
  saved_workspaces+=("${workspace}")
  saved_app_names+=("${app_name}")
  saved_titles+=("${title}")
  saved_profiles+=("$(extract_profile "${title}")")
done <<< "${windows}"

expected=${#saved_workspaces[@]}
old_ids=$(get_chrome_windows | cut -d'|' -f1 | sort)

# Trigger restart
osascript -e 'tell application "Google Chrome" to open location "chrome://restart"'

# Wait for old windows to disappear
timeout=90
elapsed=0
while (( elapsed < timeout )); do
  cur_ids=$(get_chrome_windows | cut -d'|' -f1 | sort)
  if [[ "${cur_ids}" != "${old_ids}" ]]; then
    break
  fi
  sleep 0.5
  (( ++elapsed ))
done

# Wait for all windows to reappear
current=0
while (( elapsed < timeout )); do
  current=$(get_chrome_windows | wc -l)
  if (( current >= expected )); then
    break
  fi
  sleep 1
  (( ++elapsed ))
done

# Wait for titles to stabilize
prev_titles=""
stable=0
while (( elapsed < timeout && stable < 2 )); do
  cur_titles=$(get_chrome_windows | cut -d'|' -f3- | sort)
  if [[ "${cur_titles}" == "${prev_titles}" ]]; then
    (( ++stable ))
  else
    stable=0
  fi
  prev_titles="${cur_titles}"
  sleep 1
  (( ++elapsed ))
done

# Build arrays of current windows
cur_ids=()
cur_workspaces=()
cur_app_names=()
cur_titles=()
while IFS='|' read -r wid workspace app_name title; do
  cur_ids+=("${wid}")
  cur_workspaces+=("${workspace}")
  cur_app_names+=("${app_name}")
  cur_titles+=("${title}")
done < <(get_chrome_windows)

declare -A matched_current matched_saved
moved=0
already=0
unmatched=0

move_or_count() {
  local -i ci=$1
  local target_ws="$2"
  matched_current[${ci}]=1
  if [[ "${cur_workspaces[${ci}]}" == "${target_ws}" ]]; then
    (( ++already ))
  else
    aerospace move-node-to-workspace "${target_ws}" --window-id "${cur_ids[${ci}]}" 2>/dev/null || true
    (( ++moved ))
  fi
}

# PWA pass: match by app name
for (( i = 0; i < expected; i++ )); do
  if [[ "${saved_app_names[${i}]}" == "Google Chrome" ]]; then
    continue
  fi
  for (( j = 0; j < ${#cur_ids[@]}; j++ )); do
    if [[ -z "${matched_current[${j}]:-}" && "${cur_app_names[${j}]}" == "${saved_app_names[${i}]}" ]]; then
      matched_saved[${i}]=1
      move_or_count "${j}" "${saved_workspaces[${i}]}"
      break
    fi
  done
done

# Pass 1: exact title match
for (( i = 0; i < expected; i++ )); do
  if [[ -n "${matched_saved[${i}]:-}" ]]; then
    continue
  fi
  for (( j = 0; j < ${#cur_ids[@]}; j++ )); do
    if [[ -z "${matched_current[${j}]:-}" && "${cur_app_names[${j}]}" == "Google Chrome" && "${cur_titles[${j}]}" == "${saved_titles[${i}]}" ]]; then
      matched_saved[${i}]=1
      move_or_count "${j}" "${saved_workspaces[${i}]}"
      break
    fi
  done
done

# Pass 2: same-profile word overlap
for (( i = 0; i < expected; i++ )); do
  if [[ -n "${matched_saved[${i}]:-}" ]]; then
    continue
  fi
  saved_tab=$(extract_tab_title "${saved_titles[${i}]}")
  best_j=-1
  best_overlap=0
  for (( j = 0; j < ${#cur_ids[@]}; j++ )); do
    if [[ -n "${matched_current[${j}]:-}" || "${cur_app_names[${j}]}" != "Google Chrome" ]]; then
      continue
    fi
    if [[ "$(extract_profile "${cur_titles[${j}]}")" != "${saved_profiles[${i}]}" ]]; then
      continue
    fi
    overlap=$(word_overlap "${saved_tab}" "$(extract_tab_title "${cur_titles[${j}]}")")
    if (( overlap > best_overlap )); then
      best_overlap=${overlap}
      best_j=${j}
    fi
  done
  if (( best_j >= 0 )); then
    matched_saved[${i}]=1
    move_or_count "${best_j}" "${saved_workspaces[${i}]}"
  fi
done

# Pass 3: same profile only
for (( i = 0; i < expected; i++ )); do
  if [[ -n "${matched_saved[${i}]:-}" ]]; then
    continue
  fi
  for (( j = 0; j < ${#cur_ids[@]}; j++ )); do
    if [[ -n "${matched_current[${j}]:-}" || "${cur_app_names[${j}]}" != "Google Chrome" ]]; then
      continue
    fi
    if [[ "$(extract_profile "${cur_titles[${j}]}")" == "${saved_profiles[${i}]}" ]]; then
      matched_saved[${i}]=1
      move_or_count "${j}" "${saved_workspaces[${i}]}"
      break
    fi
  done
  if [[ -z "${matched_saved[${i}]:-}" ]]; then
    (( ++unmatched ))
  fi
done

aerospace workspace "${original_workspace}" 2>/dev/null || true

result="${moved} moved, ${already} already correct"
if (( unmatched > 0 )); then
  result="${result}, ${unmatched} unmatched"
fi
echo "Restarted Chrome: ${result}"
