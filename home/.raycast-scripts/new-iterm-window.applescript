#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title New iTerm Window
# @raycast.mode silent
# @raycast.icon /Applications/iTerm.app/Contents/Resources/AppIcon.png
# @raycast.packageName Window Manager

tell application "iTerm2"
    create window with default profile command "/usr/bin/env LC_ALL=en_US.UTF-8 /bin/zsh -l"
end tell

return
