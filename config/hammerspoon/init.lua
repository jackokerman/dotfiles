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

-- Load local config if present (machine-specific initialization)
local localInit = hs.configdir .. "/init-local.lua"
if hs.fs.attributes(localInit) then
    dofile(localInit)
end

-- Start spoons after configuration
spoon.RichLinkCopy:start()
spoon.SmartLinkManager:start()
