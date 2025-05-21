-- Load custom modules
require("rich-link-copy")

-- This spoon is used to automatically download and install other spoons so the
-- SpoonInstall spooin itself is the only spoon that needs to be downloaded and
-- installed manually. 
hs.loadSpoon("SpoonInstall")

-- Automatically reload the configuration when it is changed
spoon.SpoonInstall:andUse("ReloadConfiguration")
hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()
