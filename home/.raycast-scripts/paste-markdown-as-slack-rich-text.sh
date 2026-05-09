#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Paste Markdown as Slack Rich Text
# @raycast.mode silent
# @raycast.icon ✍️
# @raycast.packageName Writing

set -euo pipefail

script_dir=${0:A:h}

"${script_dir}/copy-markdown-as-slack-rich-text.js" >/dev/null

/usr/bin/osascript >/dev/null 2>&1 <<'EOF' &!
set maxAttempts to 20
set currentFrontmostApp to ""

repeat maxAttempts times
    tell application "System Events"
        set currentFrontmostApp to name of first application process whose frontmost is true
    end tell

    if currentFrontmostApp is not "Raycast" then
        exit repeat
    end if

    delay 0.1
end repeat

if currentFrontmostApp is "Raycast" then
    return
end if

delay 0.05

tell application "System Events"
    keystroke "v" using command down
end tell
EOF
