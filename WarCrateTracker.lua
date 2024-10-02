local addonName, NS = ...

NS.recent = {}
NS.last_timestamp = 0
NS.debug = false
NS.alerted = {}
NS.menu = {}
NS.timer = nil
NS.settingsCategoryID = nil
NS.seenVignetteGUIDs = {}
NS.frequency = {[2274]=1200,[1978]=2700}

local function debugPrint(...)
    if NS.debug then
        print(...)
    end
end
NS.debugPrint = debugPrint
