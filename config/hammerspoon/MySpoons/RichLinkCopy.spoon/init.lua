--- === RichLinkCopy ===
---
--- Copy rich links from Chrome tabs
---
--- Originally adapted from: https://github.com/dbalatero/dotfiles/blob/96481582a0a4b77180afeeea9f9f14b1d8305e32/hammerspoon/rich-link-copy.lua
---
--- Configuration:
--- The spoon is now configurable to add custom remove patterns:
--- 
--- 1. Add custom remove patterns:
---    spoon.RichLinkCopy:addRemovePattern(" %| CompanyName")
---
--- Configuration should be done before calling :start()

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "RichLinkCopy"
obj.version = "1.0"
obj.author = "Jack Okerman"
obj.homepage = "https://github.com/jackokerman/dotfiles"
obj.license = "MIT"

-- Configuration
obj.hotkey = {"cmd", "shift", "c"}

-- Default remove patterns (can be extended with addRemovePattern)
obj.removePatterns = {
  "- - Google Chrome.*",
  " %- Google Docs",
  " %- Google Sheets", 
  " %- Google Drive",
  " %- Jira",
  " – Figma",
  -- Notion's "(9+) " comment indicator (can be removed if not needed)
  "%(%d+%+*%) ",
  -- Confluence: Remove " - Confluence" suffix
  " %- Confluence",
}

-- Default title formatters
obj.titleFormatters = {
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
  -- Confluence: Extract meaningful part of title
  ["confluence"] = {
    pattern = "confluence", 
    format = function(title)
      -- Remove the space and owner information (e.g., " - People & Workplace")
      local cleanTitle = title:match("^(.+) %- [^-]+$")
      if cleanTitle then
        return cleanTitle
      else
        return title
      end
    end
  },
}

local utf8 = require("utf8")

--- RichLinkCopy:addRemovePattern(pattern)
--- Method
--- Add a custom remove pattern for title cleaning
---
--- Parameters:
---  * pattern - Lua pattern string to remove from titles
function obj:addRemovePattern(pattern)
  table.insert(self.removePatterns, pattern)
  print("Added remove pattern:", pattern)
  return self
end

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
  for _, pattern in ipairs(obj.removePatterns) do
    title = string.gsub(title, pattern, "")
  end

  -- Get the current URL from the address bar.
  script = [[
    tell application "Google Chrome"
      get URL of active tab of first window
    end tell
  ]]

  local _, url = hs.osascript.applescript(script)

  -- Apply title formatting based on URL
  for _, formatter in pairs(obj.titleFormatters) do
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

--- RichLinkCopy:copyRichLink()
--- Method
--- Copy rich link from current Chrome tab
---
--- Parameters:
---  * None
function obj:copyRichLink()
  getRichLinkToCurrentChromeTab()
end

--- RichLinkCopy:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for RichLinkCopy
---
--- Parameters:
---  * mapping - A table containing hotkey mappings for the spoon
function obj:bindHotkeys(mapping)
  local spec = {
    copy = hs.fnutils.partial(self.copyRichLink, self)
  }
  hs.spoons.bindHotkeysToSpec(spec, mapping)
  return self
end

--- RichLinkCopy:start()
--- Method
--- Start the spoon
---
--- Parameters:
---  * None
function obj:start()
  -- Note: Hotkeys should be bound explicitly via bindHotkeys() method
  -- to avoid conflicts with other hotkey bindings
  return self
end

--- RichLinkCopy:stop()
--- Method
--- Stop the spoon
---
--- Parameters:
---  * None
function obj:stop()
  -- Unbind hotkeys if needed
  -- Note: hs.hotkey doesn't have a direct unbind method, 
  -- but the hotkey will be automatically cleaned up when Hammerspoon reloads
  return self
end

return obj 
