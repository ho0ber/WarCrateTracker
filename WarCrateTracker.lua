local addonName, NS = ...

NS.currentShard = nil
NS.currentZone = nil
NS.recent = {}
NS.last_timestamp = 0
NS.debug = false
NS.alerted = {}
NS.menu = {}
NS.timer = nil
NS.settingsCategoryID = nil
NS.seenVignetteGUIDs = {}
NS.crateVignetteIDs = {
    [3689] = {name="plane", abbr="^", vignetteID=3689},
    [2967] = {name="parachute", abbr="*", vignetteID=2967},
    [6066] = {name="unclaimed", abbr="X", vignetteID=6066},
    [6068] = {name="claimed", abbr="_", vignetteID=6068},
}
NS.zoneConfig = {
    -- The War Within, Khaz Algar
    [2248] = {exp="TWW", name="Isle of Dorn",  shortname="Dorn",    abbr="KA:Dn",  frequency=1098, remap=nil},
    [2328] = {exp="TWW", name="Isle of Dorn",  shortname="Dorn",    abbr="KA:Dn",  frequency=1098, remap=2248}, --The Proscenium
    [2214] = {exp="TWW", name="Ringing Deeps", shortname="Deeps",   abbr="KA:RD",  frequency=1095, remap=nil},
    [2215] = {exp="TWW", name="Hallowfall",    shortname="Hallow",  abbr="KA:Ha",  frequency=1095, remap=nil},
    [2255] = {exp="TWW", name="Azj-Kahet",     shortname="Azj-K",   abbr="KA:AK",  frequency=1095, remap=nil},
    [2213] = {exp="TWW", name="Azj-Kahet",     shortname="Azj-K",   abbr="KA:AK",  frequency=1095, remap=2255}, --City of Threads Umbral Bazaar
    [2216] = {exp="TWW", name="Azj-Kahet",     shortname="Azj-K",   abbr="KA:AK",  frequency=1095, remap=2255}, --Ara-Kara City of Echoes
    [2255] = {exp="TWW", name="Azj-Kahet",     shortname="Azj-K",   abbr="KA:AK",  frequency=1095, remap=2255}, --Ara-Kara City of Threads
    [2369] = {exp="TWW", name="Siren Isle",    shortname="Siren",   abbr="KA:SI",  frequency=1095, remap=nil},
    [2346] = {exp="TWW", name="Undermine",     shortname="Under",   abbr="KA:UM",  frequency=1095, remap=nil},
    [2371] = {exp="TWW", name="K'aresh",       shortname="K'aresh", abbr="KA:Ka",  frequency=1095, remap=nil},
    [2472] = {exp="TWW", name="K'aresh",       shortname="K'aresh", abbr="KA:Ka",  frequency=1095, remap=2371},
    -- Dragonflight
    [2022] = {exp="DF", name="Waking Shore",     shortname="Shore",  abbr="DF:WS", frequency=2720, remap=nil},
    [2023] = {exp="DF", name="Ohn'ahran Plains", shortname="Plains", abbr="DF:OP", frequency=2720, remap=nil},
    [2239] = {exp="DF", name="Ohn'ahran Plains", shortname="Plains", abbr="DF:OP", frequency=2720, remap=2023}, --Bel'ameth
    [2024] = {exp="DF", name="The Azure Span",   shortname="Span",   abbr="DF:AS", frequency=2720, remap=nil},
    [2025] = {exp="DF", name="Thaldraszus",      shortname="Thald",  abbr="DF:Th", frequency=2720, remap=nil},
    [2151] = {exp="DF", name="Forbidden Reach",  shortname="Reach",  abbr="DF:FR", frequency=2720, remap=nil},
    [2133] = {exp="DF", name="Zarelek Cavern",   shortname="Cavern", abbr="DF:ZK", frequency=2720, remap=nil},
    [2200] = {exp="DF", name="Emerald Dream",    shortname="Dream",  abbr="DF:ED", frequency=2720, remap=nil},
}

NS.MSG_CRATE_WARN = "War Crate in %s - %s"
NS.MSG_CRATE_ALERT = "War Crate in %s - %s in %s"
NS.MSG_CRATE = "%s just announced a war crate in %s - %s (heard by %s)"
NS.MSG_CRATE_SPOT = "War crate in %s - %s (spotted by %s - %s)"

NS.WINDOW_LABEL = "%i. %s - %s - %s (%ix)"
NS.WINDOW_TIMER = "%s %s"

local function debugPrint(...)
    if NS.debug or (settings ~= nil and settings["debug"]) then
        print("WCT::", ...)
    end
end
NS.debugPrint = debugPrint
