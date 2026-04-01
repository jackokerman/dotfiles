-- This spoon is used to automatically download and install other spoons so the
-- SpoonInstall spoon itself is the only spoon that needs to be downloaded and
-- installed manually. 
hs.loadSpoon("SpoonInstall")
-- Ensure that all spoons are installed synchronously and can be used
-- immediately on first use.
spoon.SpoonInstall.use_syncinstall = true

-- Add custom spoon directory to package path
package.path = package.path .. ";" .. hs.configdir .. "/MySpoons/?.spoon/init.lua"

-- Automatically reload the configuration when it is changed
spoon.SpoonInstall:andUse("ReloadConfiguration", {
    start = true
})

-- Load all dependencies first (but don't start URLDispatcher yet)
spoon.SpoonInstall:andUse("URLDispatcher", {
    start = false
})

-- Load your custom spoons
hs.loadSpoon("RichLinkCopy")
hs.loadSpoon("SmartLinkManager")

-- Configure and start RichLinkCopy
spoon.RichLinkCopy:bindHotkeys({
    copy = {{"cmd", "shift"}, "c"}
})

-- Toggle Chrome vertical tabs sidebar (Cmd+S, Chrome-only)
local function toggleChromeVerticalTabs()
    local chrome = hs.application.get("com.google.Chrome")
    if not chrome then
        hs.alert.show("Chrome not running")
        return
    end

    local win = chrome:mainWindow()
    if not win then
        hs.alert.show("No Chrome window")
        return
    end

    local axWin = hs.axuielement.windowElement(win)
    local targets = {
        ["Expand tabs"] = true, ["Collapse tabs"] = true,
        ["Expand Tabs"] = true, ["Collapse Tabs"] = true,
    }

    local function findButton(el, depth)
        if depth > 10 then
            return nil
        end
        local role = el:attributeValue("AXRole") or ""
        local title = el:attributeValue("AXTitle") or ""
        local desc = el:attributeValue("AXDescription") or ""
        if role == "AXButton" and (targets[title] or targets[desc]) then
            return el
        end
        for _, child in ipairs(el:attributeValue("AXChildren") or {}) do
            local found = findButton(child, depth + 1)
            if found then
                return found
            end
        end
        return nil
    end

    local btn = findButton(axWin, 0)
    if btn then
        btn:performAction("AXPress")
    else
        hs.alert.show("Sidebar button not found")
    end
end

local chromeFilter = hs.window.filter.new("Google Chrome")
local chromeTabToggle = hs.hotkey.new({"cmd"}, "s", toggleChromeVerticalTabs)
chromeFilter:subscribe(hs.window.filter.windowFocused, function() chromeTabToggle:enable() end)
chromeFilter:subscribe(hs.window.filter.windowUnfocused, function() chromeTabToggle:disable() end)


-- Load local config if present (machine-specific initialization)
local localInit = hs.configdir .. "/init.local.lua"
if hs.fs.attributes(localInit) then
    dofile(localInit)
end

-- Start spoons after configuration
spoon.RichLinkCopy:start()
spoon.SmartLinkManager:start()
