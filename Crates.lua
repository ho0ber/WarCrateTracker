local addonName, NS = ...

-- Add a simple function that returns a table with:
---- zoneID, zoneParentID, zoneName, zoneParentName, crateTS, nextCrateTS, crateStaleCount, certainty (was it a spot or an announce)

local function shouldAnnounce(zoneParentID)
    return not ((zoneParentID == 2274 and not settings["twwAnnounce"]) or (zoneParentID == 1978 and not settings["dfAnnounce"]))
end
NS.shouldAnnounce = shouldAnnounce

local function shouldTrack(zoneParentID)
    return not ((zoneParentID == 2274 and not settings["twwTrack"]) or (zoneParentID == 1978 and not settings["dfTrack"]))
end
NS.shouldTrack = shouldTrack

local function shouldWarn(zoneParentID)
    return not ((zoneParentID == 2274 and not settings["twwWarn"]) or (zoneParentID == 1978 and not settings["dfWarn"]))
end
NS.shouldWarn = shouldWarn

local function sendAnnouncement(zoneID, zoneParentID, curTime, announcer)
    local message = NS.ADDON_MSG:format("ANNOUNCE", zoneID, zoneParentID, curTime, announcer)
    print("sending:",message)
    ChatThrottleLib:SendAddonMessage("NORMAL",  "WarCrateTracker", message, "CHANNEL", "WarCrateTracker");
end
NS.sendAnnouncement = sendAnnouncement

local function sendSpot(zoneID, zoneParentID, curTime, method)
    local message = NS.ADDON_MSG:format("SPOT", zoneID, zoneParentID, curTime, method)
    print("sending:",message)
    ChatThrottleLib:SendAddonMessage("NORMAL",  "WarCrateTracker", message, "CHANNEL", "WarCrateTracker");
end
NS.sendSpot = sendSpot

local function doAnnounce(announcer, zoneID, zoneParentID, ts, player)
    if crateDB[zoneID] ~= nil then
        local delta = ts - crateDB[zoneID]
        if delta < 30 and delta > -30 then
            print("Ignoring announcement from ", player, "delta is", delta)
            return
        end
    end
    if shouldAnnounce(zoneParentID) then
        local zoneName = C_Map.GetMapInfo(zoneID).name
        local zoneParentName = C_Map.GetMapInfo(zoneParentID).name

        RaidNotice_AddMessage(RaidWarningFrame, NS.MSG_CRATE_WARN:format(zoneName, zoneParentName),ChatTypeInfo["RAID_WARNING"]);
        PlaySoundFile("Interface\\AddOns\\WarCrateTracker\\shipswhistle.ogg", "Master")
        
        if announcer == nil then
            print(NS.MSG_CRATE_SPOT:format(zoneName, zoneParentName, player))
        else
            print(NS.MSG_CRATE:format(announcer, zoneName, zoneParentName, player))
        end

        local lastTime = crateDB[zoneID]
        if lastTime ~= nil then
            local nc = NS.nextCrate(zoneID, lastTime, ts)
            local stale = NS.lastCrateStaleness(zoneID, lastTime, ts)
            print(NS.MSG_LAST:format(zoneParentName, zoneName, ts-lastTime, stale, nc))
        else
            print(NS.MSG_NODB:format(zoneName))
        end
    end
    crateDB[zoneID] = ts
end
NS.doAnnounce = doAnnounce

local function crateAnnounced(announcer, text)
    local zoneID = C_Map.GetBestMapForUnit("player")
    local zoneName = C_Map.GetMapInfo(zoneID).name
    local zoneParentID = C_Map.GetMapInfo(zoneID).parentMapID
    local zoneParentName = C_Map.GetMapInfo(zoneParentID).name
    local player = UnitName("player")
    local curTime = GetServerTime()
    
    sendAnnouncement(zoneID, zoneParentID, curTime, announcer)
    doAnnounce(announcer, zoneID, zoneParentID, curTime, player)
end
NS.crateAnnounced = crateAnnounced

local function crateSpotted(method)
    local zoneID = C_Map.GetBestMapForUnit("player")
    local zoneName = C_Map.GetMapInfo(zoneID).name
    local zoneParentID = C_Map.GetMapInfo(zoneID).parentMapID
    local zoneParentName = C_Map.GetMapInfo(zoneParentID).name
    local player = UnitName("player")
    local curTime = GetServerTime()

    print("Crate spotted in", zoneName, "via method", method, "- deciding if should be announced")
    
    if crateDB[zoneID] == nil or (curTime - crateDB[zoneID]) > 180 then
        sendSpot(zoneID, zoneParentID, curTime, method)
        doAnnounce(nil, zoneID, zoneParentID, curTime, player)
    end
end
NS.crateSpotted = crateSpotted

local function compareZones(z1, z2)
    local curTime = GetServerTime()
    local ts1 = NS.nextCrateTS(z1, crateDB[z1], curTime)
    local ts2 = NS.nextCrateTS(z2, crateDB[z2], curTime)
    if ts1 == nil then
        return false
    elseif ts2 == nil then
        return true
    end
    return ts1 < ts2
end
NS.compareZones = compareZones

local function sortedZones()
    local zones = {}
    for k, v in pairs(crateDB) do
        if v ~= nil then
            table.insert(zones, k)
        end
    end
    table.sort(zones, compareZones)
    return zones
end
NS.sortedZones = sortedZones

function alert(zoneID, last, current)
    -- print("Checking crates for alerts...")
    local nextTS = NS.nextCrateTS(zoneID, last, current)
    local nextIn = NS.nextCrateTS(zoneID, last, current)-current
    if nextIn <= 180 then
        local alertKey = format("%i-%i", zoneID, nextTS)
        if NS.alerted[alertKey] == nil then
            local nextCrateText = nextCrate(zoneID, last, current)
            local zoneName = C_Map.GetMapInfo(zoneID).name
            local zoneParentID = C_Map.GetMapInfo(zoneID).parentMapID
            local zoneParentName = C_Map.GetMapInfo(zoneParentID).name
            RaidNotice_AddMessage(RaidWarningFrame,NS.MSG_CRATE_ALERT:format(zoneName, zoneParentName, nextCrateText),ChatTypeInfo["RAID_WARNING"]);
            PlaySound(8232, "Master")
            NS.alerted[alertKey] = true
        end
        
    end
end
NS.alert = alert
