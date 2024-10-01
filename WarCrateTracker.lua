local addonName, NS = ...

NS.recent = {}
NS.last_timestamp = 0
NS.debug = true
NS.alerted = {}
NS.menu = {}
NS.timer = nil
NS.settingsCategoryID = nil
NS.seenVignetteGUIDs = {}
NS.frequency = {[2274]=1200,[1978]=2700}

local function debugPrint(message)
    if NS.debug then
        print(message)
    end
end
NS.debugPrint = debugPrint
