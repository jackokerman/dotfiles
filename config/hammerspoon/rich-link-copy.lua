-- Originally adapted from: https://github.com/dbalatero/dotfiles/blob/main/hammerspoon/rich-link-copy.lua
local utf8 = require("utf8")

-- Copies a rich link to your currently visible Chrome browser tab that you
-- can paste into Slack/anywhere else that supports it.
--
-- Link is basically formatted as:
--
--   <a href="http://the.url.com">Page title</a>
local function getRichLinkToCurrentChromeTab()
  local application = hs.application.frontmostApplication()

  -- Only copy from Chrome
  if application:bundleID() ~= "com.google.Chrome" then
    return
  end

  -- Grab the <title> from the page.
  local script = [[
    tell application "Google Chrome"
      get title of active tab of first window
    end tell
  ]]

  local _, title = hs.osascript.applescript(script)

  -- Remove trailing garbage from window title for a better looking link.
  local removePatterns = {
    "- - Google Chrome.*",
    " %- Google Docs",
    " %- Google Sheets",
    " %- Google Drive",
    " %- Jira",
    " – Figma",
    -- Notion's "(9+) " comment indicator (can be removed if not needed)
    "%(%d+%+*%) ",
  }

  for _, pattern in ipairs(removePatterns) do
    title = string.gsub(title, pattern, "")
  end

  -- Get the current URL from the address bar.
  script = [[
    tell application "Google Chrome"
      get URL of active tab of first window
    end tell
  ]]

  local _, url = hs.osascript.applescript(script)

  -- Format titles based on URL patterns
  local titleFormatters = {
    -- Jira: Use less strict pattern for ticket number
    ["jira"] = {
      pattern = "jira",
      format = function(title)
        local ticket, rest = title:match("%[(.-)%]%s*(.*)")
        if ticket and rest and ticket ~= "" then
          return ticket .. ": " .. rest
        else
          return title
        end
      end
    },
  }

  -- Apply title formatting based on URL
  for _, formatter in pairs(titleFormatters) do
    if url:find(formatter.pattern) then
      title = formatter.format(title)
      break
    end
  end

  -- Encode the title as html entities like (&#107;&#84;), so that we can
  -- print out unicode characters inside of `getStyledTextFromData` and have
  -- them render correctly in the link.
  local encodedTitle = ""

  for _, code in utf8.codes(title) do
    encodedTitle = encodedTitle .. "&#" .. code .. ";"
  end

  -- Embed the URL + title in an <a> tag so macOS converts it to a rich link
  -- on paste.
  local html = '<a href="' .. url .. '">' .. encodedTitle .. "</a>"

  -- Insert the styled link into the clipboard
  local styledText = hs.styledtext.getStyledTextFromData(html, "html")
  hs.pasteboard.writeObjects(styledText)

  hs.alert('Copied link to "' .. title .. '"')
end

-- Bind to Cmd+Shift+C instead of hyperKey
hs.hotkey.bind({"cmd", "shift"}, "c", getRichLinkToCurrentChromeTab) 
