-- Load custom modules
require("rich-link-copy")

-- This spoon is used to automatically download and install other spoons so the
-- SpoonInstall spooin itself is the only spoon that needs to be downloaded and
-- installed manually. 
hs.loadSpoon("SpoonInstall")
-- Ensure that all spoons are installed synchronously and can be used
-- immediately on first use.
spoon.SpoonInstall.use_syncinstall = true

-- Automatically reload the configuration when it is changed
spoon.SpoonInstall:andUse("ReloadConfiguration", {
    start = true
})
