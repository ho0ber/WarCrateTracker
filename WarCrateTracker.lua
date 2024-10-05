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
NS.methods = {
    heard="!", -- announced by NPC in zone
    plane="^", -- plane spotted
    parachute="*", -- parachute spotted
    unclaimed="X", -- unclaimed crate spotted (up to 10 minutes late)
    claimed="_", -- claimed crate spotted (up to 10 minutes late)
    manual="/", -- a manually added spot
    unknown="?", -- migrated from old db
}

NS.MSG_CRATE_WARN = "War Crate in %s - %s"
NS.MSG_CRATE_ALERT = "War Crate in %s - %s in %s"
NS.MSG_CRATE = "%s just announced a war crate in %s - %s (heard by %s)"
NS.MSG_CRATE_SPOT = "War crate in %s - %s (spotted by %s - %s)"

NS.WINDOW_LABEL = "%i. %s - %s (%ix)"
NS.WINDOW_TIMER = "%s %s"

local function debugPrint(...)
    if NS.debug or settings.debug then
        print(...)
    end
end
NS.debugPrint = debugPrint
