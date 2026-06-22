--- === NoTunes ===
---
--- Prevent Apple Music or iTunes from launching.

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "NoTunes"
obj.version = "1.0"
obj.author = "Jack Okerman"
obj.homepage = "https://github.com/jackokerman/dotfiles"
obj.license = "MIT"

local blockedBundleIDs = {
    ["com.apple.Music"] = true,
    ["com.apple.iTunes"] = true,
}

function obj:blockApp(app)
    local bundleID = app and app:bundleID()
    if blockedBundleIDs[bundleID] ~= true then
        return
    end

    local appName = app:name() or bundleID
    print("NoTunes: blocking " .. appName .. " (" .. bundleID .. ")")
    app:kill9()
end

function obj:blockRunningApps()
    for bundleID, _ in pairs(blockedBundleIDs) do
        for _, app in ipairs(hs.application.applicationsForBundleID(bundleID)) do
            self:blockApp(app)
        end
    end
end

--- NoTunes:start()
--- Method
--- Start blocking Apple Music and iTunes launches.
function obj:start()
    if self.watcher then
        return self
    end

    self:blockRunningApps()

    self.watcher = hs.application.watcher.new(function(_, eventType, app)
        if eventType == hs.application.watcher.launching or eventType == hs.application.watcher.launched then
            self:blockApp(app)
        end
    end)
    self.watcher:start()

    return self
end

--- NoTunes:stop()
--- Method
--- Stop blocking Apple Music and iTunes launches.
function obj:stop()
    if self.watcher then
        self.watcher:stop()
        self.watcher = nil
    end

    return self
end

return obj
