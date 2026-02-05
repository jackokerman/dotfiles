--- === SmartLinkManager ===
---
--- Route URLs to different Chrome profiles based on URL patterns
---
--- Automatically routes URLs to appropriate Chrome profiles for work/personal separation

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "SmartLinkManager"
obj.version = "1.0"
obj.author = "Jack Okerman"
obj.homepage = "https://github.com/jackokerman/dotfiles"
obj.license = "MIT"

-- Chrome profile routing function
local function sendToChromeProfile(match, profileName)
    local fn = function(url)
        print("Accessing URL", url, "in Chrome profile:", profileName)
        local t = hs.task.new(
            "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
            nil,
            function() return false end,
            {"--profile-directory=" .. profileName, url}
        )
        t:start()
    end
    return {match, nil, fn}
end

--- SmartLinkManager:addChromeUrlPattern(pattern, profileName)
--- Method
--- Add a URL pattern to route to a specific Chrome profile
---
--- Parameters:
---  * pattern - Lua pattern string to match URLs
---  * profileName - Chrome profile name
function obj:addChromeUrlPattern(pattern, profileName)
    return self:addUrlPattern(pattern, function(p) return sendToChromeProfile(p, profileName) end)
end

--- SmartLinkManager:addUrlPattern(pattern, browserFunction)
--- Method
--- Add a URL pattern to route to a specific browser/profile
---
--- Parameters:
---  * pattern - Lua pattern string to match URLs
---  * browserFunction - Function that creates a URL pattern
function obj:addUrlPattern(pattern, browserFunction)
    if not spoon.URLDispatcher then
        error("URLDispatcher must be loaded before adding URL patterns")
    end
    
    -- Initialize url_patterns if it doesn't exist
    if not spoon.URLDispatcher.url_patterns then
        spoon.URLDispatcher.url_patterns = {}
    end
    
    -- Add the pattern to URLDispatcher using the provided browser function
    table.insert(spoon.URLDispatcher.url_patterns, browserFunction(pattern))
    print("Added URL pattern:", pattern)
    return self
end

--- SmartLinkManager:start(startUrlDispatcher)
--- Method
--- Start the SmartLinkManager and optionally URLDispatcher
---
--- Parameters:
---  * startUrlDispatcher - Boolean, whether to start URLDispatcher (defaults to true)
function obj:start(startUrlDispatcher)
    -- Default to true for convenience
    if startUrlDispatcher == nil then
        startUrlDispatcher = true
    end
    
    -- Print available Chrome profiles on startup
    local profiles = self:listChromeProfiles()
    print("Available Chrome profiles for URL routing:")
    for i, profile in ipairs(profiles) do
        print("  " .. i .. ". " .. profile)
    end

    print("Smart Link Manager loaded - use addUrlPattern to configure URL routing")
    
    -- Start URLDispatcher if requested
    if startUrlDispatcher then
        if not spoon.URLDispatcher then
            error("URLDispatcher must be loaded before starting SmartLinkManager")
        end
        spoon.URLDispatcher:start()
        print("URLDispatcher started")
    else
        print("URLDispatcher not started - call spoon.URLDispatcher:start() manually if needed")
    end
    
    return self
end

--- SmartLinkManager:stop()
--- Method
--- Stop the SmartLinkManager
function obj:stop()
    -- Stop URLDispatcher
    spoon.URLDispatcher:stop()
    return self
end

--- SmartLinkManager:listChromeProfiles()
--- Method
--- List all available Chrome profiles with their display names
---
--- Returns:
---  * Table of profile information strings
function obj:listChromeProfiles()
    local chromeDataDir = os.getenv("HOME") .. "/Library/Application Support/Google/Chrome"
    local profileDirs = {"Default", "Profile 1"}
    local profiles = {}
    
    for i, profileDir in ipairs(profileDirs) do
        local prefsPath = chromeDataDir .. "/" .. profileDir .. "/Preferences"
        local displayName = profileDir
        
        -- Try to read the display name from Chrome's Preferences file
        if hs.fs.attributes(prefsPath) then
            local file = io.open(prefsPath, "r")
            if file then
                local content = file:read("*all")
                file:close()
                
                -- Look for the profile name in the JSON
                local customName = content:match('"name":"([^"]+)"')
                if customName then
                    displayName = customName
                end
            end
        end
        
        local profileInfo = profileDir .. " (" .. displayName .. ")"
        table.insert(profiles, profileInfo)
    end
    
    return profiles
end

--- SmartLinkManager:showChromeProfiles()
--- Method
--- Display Chrome profiles in an alert
function obj:showChromeProfiles()
    local profiles = self:listChromeProfiles()
    local message = "Chrome Profiles Found:\n"
    for i, profile in ipairs(profiles) do
        message = message .. i .. ". " .. profile .. "\n"
    end
    hs.alert(message)
    return self
end

--- SmartLinkManager:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for SmartLinkManager
---
--- Parameters:
---  * mapping - A table containing hotkey mappings for the spoon
function obj:bindHotkeys(mapping)
    local spec = {
        showChromeProfiles = hs.fnutils.partial(self.showChromeProfiles, self)
    }
    hs.spoons.bindHotkeysToSpec(spec, mapping)
    return self
end

return obj 
