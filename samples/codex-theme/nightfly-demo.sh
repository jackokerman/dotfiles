#!/usr/bin/env bash

set -euo pipefail

theme_name="nightfly"
prompt_tint="#092236"
readonly theme_name prompt_tint

print_status() {
  local file_path="$1"

  if [[ ! -f "$file_path" ]]; then
    printf 'missing sample: %s\n' "$file_path"
    return 1
  fi

  printf 'previewing %s with %s (%s)\n' "$file_path" "$theme_name" "$prompt_tint"
}

for sample in nightfly-demo.ts nightfly-demo.md nightfly-demo.json; do
  print_status "$sample"
done

if [[ "${1:-inspect}" == "inspect" ]]; then
  echo "Compare the prompt bar against the line highlight and selection colors."
fi
