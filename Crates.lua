local addonName, NS = ...

local function convertDBEntry(zoneID, entry)
    if type(entry) == "table" then
        return entry
    end
    local zoneInfo = C_Map.GetMapInfo(zoneID)
    local zoneParentID = zoneInfo.parentMapID
    local zoneParentName = C_Map.GetMapInfo(zoneParentID).name
    local player = UnitName("player")
    local zoneName = zoneInfo.name
    return {method="unknown", ts=entry, zoneID=zoneID, zoneParentID=zoneParentID, zoneName=zoneName, zoneParentName=zoneParentName, spotter=player}
end

local function abbreviateMethod(crateInfo)
    local abbreviation = NS.methods[crateInfo.method]
    if abbreviation ~= nil then
        return abbreviation
    end
    return "?"
end
NS.abbreviateMethod = abbreviateMethod

local function convertDB()
    for k,v in pairs(crateDB) do
        crateDB[k] = convertDBEntry(k,v)
    end
end
NS.convertDB = convertDB

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

local function genCrateInfo(method)
    local zoneID = C_Map.GetBestMapForUnit("player")
    if zoneID ~= nil then
        local zoneName = C_Map.GetMapInfo(zoneID).name
        local zoneParentID = C_Map.GetMapInfo(zoneID).parentMapID
        local zoneParentName = C_Map.GetMapInfo(zoneParentID).name
        local player = UnitName("player")
        local curTime = GetServerTime()
        return {method=method, ts=curTime, zoneID=zoneID, zoneParentID=zoneParentID, zoneName=zoneName, zoneParentName=zoneParentName, spotter=player}
    end
    return nil
end

local function crateIsDupe(crateInfo)
    if crateDB[crateInfo.zoneID] == nil then
        return false
    end

    return (crateInfo.ts - crateDB[crateInfo.zoneID].ts) <= 180
end

local function sendCrate(crateInfo, sendType)
    local message = strjoin("~", sendType, crateInfo.method, tostring(crateInfo.ts), tostring(crateInfo.zoneID), tostring(crateInfo.zoneParentID), crateInfo.zoneName, crateInfo.zoneParentName, crateInfo.spotter)
    NS.debugPrint("sending:",message)
    ChatThrottleLib:SendAddonMessage("NORMAL",  "WarCrateTracker", message, "GUILD") --"CHANNEL", "WarCrateTracker");
end

local function recordCrate(crateInfo)
    if not (crateInfo.zoneParentID == 2274 or crateInfo.zoneParentID == 1978) then
        print("Ignoring bad crate - zoneParentID not in whitelist")
        return
    end

    if crateDB[crateInfo.zoneID] ~= nil and crateDB[crateInfo.zoneID].ts > crateInfo.ts then
        print("Ignoring crate information from", crateInfo.spotter, "because we have a newer spot")
        return
    end
    
    crateDB[crateInfo.zoneID] = crateInfo

end
NS.sendCrate = sendCrate

local function sendAllCrates(sendType)
    local t = sendType
    for _, crateInfo in pairs(crateDB) do
        if crateInfo ~= nil then
            sendCrate(crateInfo, t)
            if t == "LOGIN" then
                t = "UPDATE" -- Hacky solution to ensure other clients don't reply ALL crates to EACH send on login
            end
        end
    end
end
NS.sendAllCrates = sendAllCrates

local function checkDelta(crateInfo)
    if crateDB[crateInfo.zoneID] ~= nil then
        local delta = crateInfo.ts - crateDB[crateInfo.zoneID].ts
        if delta < 180 and delta > -180 then
            NS.debugPrint("Ignoring announcement from", crateInfo.spotter, "delta is", delta)
            return false
        end
    end
    return true
end

local function announceCrate(crateInfo)
    if shouldAnnounce(crateInfo) and checkDelta(crateInfo) then
        RaidNotice_AddMessage(RaidWarningFrame, NS.MSG_CRATE_WARN:format(crateInfo.zoneName, crateInfo.zoneParentName), ChatTypeInfo["RAID_WARNING"]);
        PlaySoundFile("Interface\\AddOns\\WarCrateTracker\\shipswhistle.ogg", "Master")
        print(NS.MSG_CRATE_SPOT:format(crateInfo.zoneName, crateInfo.zoneParentName, crateInfo.spotter, crateInfo.method))
    end
end

local function crateSpotted(method)
    local crateInfo = genCrateInfo(method)
    if crateInfo ~= nil then
        NS.debugPrint("Crate spotted in", crateInfo.zoneName, "via method", crateInfo.method, "- deciding if should be announced")
        if not crateIsDupe(crateInfo) then
            sendCrate(crateInfo, "SPOT")
            announceCrate(crateInfo)
            recordCrate(crateInfo)
        end
    end
end
NS.crateSpotted = crateSpotted

local function processCrateMessage(text, sender)
    local senderName, senderRealm = strsplit("-", sender, 2)
    local playerName, playerRealm = UnitFullName("player")
    if senderName == playerName and senderRealm == playerRealm then
        NS.debugPrint("Ignoring a message from myself:",sender,text)
        return
    end
    local sendType, method, ts_s, zoneID_s, zoneParentID_s, zoneName, zoneParentName, spotter = strsplit("~", text)
    local crateInfo = {method=method, ts=tonumber(ts_s), zoneID=tonumber(zoneID_s), zoneParentID=tonumber(zoneParentID_s), zoneName=zoneName, zoneParentName=zoneParentName, spotter=spotter}
    NS.debugPrint("Recieved addon message from", sender, "-", text)
    if sendType == "SPOT" then
        announceCrate(crateInfo)
        recordCrate(crateInfo)
    elseif sendType == "LOGIN" then
        recordCrate(crateInfo)
        NS.debugPrint("Heard LOGIN message - responding with our crateDB data")
        sendAllCrates("UPDATE")
    elseif sendType == "UPDATE" then
        recordCrate(crateInfo)
    end
end
NS.processCrateMessage = processCrateMessage

local function compareZones(z1, z2)
    local curTime = GetServerTime()
    local ts1 = NS.nextCrateTime(crateDB[z1], curTime)
    local ts2 = NS.nextCrateTime(crateDB[z2], curTime)
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

local function warnCrate(crateInfo, curTime)
    local nextTS = NS.nextCrateTime(crateInfo, curTime)
    if nextTS == nil then
        NS.debugPrint("nexTS was nil???", crateInfo.zoneID, crateInfo.ts, curTime)
        return
    end

    local nextIn = nextTS-curTime
    if nextIn <= 180 then
        local alertKey = format("%i-%i", crateInfo.zoneID, nextTS)
        if NS.alerted[alertKey] == nil then
            RaidNotice_AddMessage(RaidWarningFrame,NS.MSG_CRATE_ALERT:format(crateInfo.zoneName, crateInfo.zoneParentName, NS.displayTime(nextIn)),ChatTypeInfo["RAID_WARNING"]);
            PlaySound(8232, "Master")
            NS.alerted[alertKey] = true
        end
    end
end
NS.warnCrate = warnCrate
