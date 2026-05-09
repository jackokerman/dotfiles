#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Copy Markdown as Slack Rich Text
# @raycast.mode silent
# @raycast.icon 💬
# @raycast.packageName Writing

set -euo pipefail

"$HOME/.local/bin/slack-rich-text" >/dev/null
