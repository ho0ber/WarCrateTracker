local addonName, NS = ...

local function shouldAnnounce(crateInfo)
    local zoneConfig = NS.zoneConfig[crateInfo.zoneID]
    if zoneConfig.exp == "TWW" and settings["twwAnnounce"] then
        return true
    elseif zoneConfig.exp == "DF" and settings["dfAnnounce"] then
        return true
    elseif zoneConfig.exp == "BFA" and settings["bfaAnnounce"] then
        return true
    end

    return false
end
NS.shouldAnnounce = shouldAnnounce

local function shouldTrack(crateInfo)
    local zoneConfig = NS.zoneConfig[crateInfo.zoneID]
    if zoneConfig.exp == "TWW" and settings["twwTrack"] then
        return true
    elseif zoneConfig.exp == "DF" and settings["dfTrack"] then
        return true
    elseif zoneConfig.exp == "BFA" and settings["bfaTrack"] then
        return true
    end

    return false
end
NS.shouldTrack = shouldTrack

local function shouldWarn(crateInfo)
    local zoneConfig = NS.zoneConfig[crateInfo.zoneID]
    if zoneConfig.exp == "TWW" and settings["twwWarn"] then
        return true
    elseif zoneConfig.exp == "DF" and settings["dfWarn"] then
        return true
    elseif zoneConfig.exp == "BFA" and settings["bfaWarn"] then
        return true
    end

    return false
end
NS.shouldWarn = shouldWarn

local function getShardFromGUID(guid)
    local _, _, _, _, shard_id, _ = strsplit("-", guid, 6)
    return shard_id
end
NS.getShardFromGUID = getShardFromGUID

local function genCrateInfo(vignetteGUID)
    local zoneID = C_Map.GetBestMapForUnit("player")
    if zoneID == nil then
        return nil
    end
    
    local zoneConfig = NS.zoneConfig[zoneID]
    if zoneConfig == nil then
        return nil
    end
    if zoneConfig.remap ~= nil then
        zoneConfig = NS.zoneConfig[zoneConfig.remap]
    end

    local vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
    if vignetteInfo == nil then
        return nil
    end

    local shardID = getShardFromGUID(vignetteGUID)
    local method = NS.crateVignetteIDs[vignetteInfo.vignetteID]
    if method == nil then
        method = {name="unknown", abbr="?"}
    end

    local player = UnitName("player")
    local curTime = GetServerTime()

    return {
        guid=vignetteGUID,
        method=method,
        ts=curTime,
        zoneID=zoneID,
        shardID=shardID,
        spotter=player
    }
end

local function crateIsDupe(crateInfo)
    local existing = NS.getCrateFromDB(crateInfo.zoneID, crateInfo.shardID)
    if existing == nil then
        return false
    end

    if existing.guid == crateInfo.guid then
        return true
    end

    return (crateInfo.ts - existing.ts) <= 180
end

local function recordCrate(crateInfo)
    local existing = NS.getCrateFromDB(crateInfo.zoneID, crateInfo.shardID)

    if existing ~= nil and existing.ts > crateInfo.ts then
        NS.debugPrint("Ignoring crate information from", crateInfo.spotter, "because we have a newer spot")
        return
    end

    if existing  ~= nil and existing.ts + 600 > crateInfo.ts and (crateInfo.method.name == "unclaimed" or crateInfo.method.name == "claimed") then
        NS.debugPrint("Ignoring crate information from", crateInfo.spotter, "because we have a better spot")
        return
    end
    
    NS.debugPrint("Writing crate to db", crateInfo.guid)
    NS.saveCrateToDB(crateInfo)
end
NS.recordCrate = recordCrate

local function sendAllCrates(sendType)
    local t = sendType
    local curTime = GetServerTime()
    for _, crateInfo in pairs(crateDB) do
        if crateInfo ~= nil then
            if curTime - crateInfo.ts <= 86400 then 
                NS.sendCrate(crateInfo, t)
                if t == "REQUEST_V2" then
                    t = "UPDATE_V2" -- Hacky solution to ensure other clients don't reply ALL crates to EACH send on login
                end
            end
        end
    end
end
NS.sendAllCrates = sendAllCrates

local function checkDelta(crateInfo)
    local existing = NS.getCrateFromDB(crateInfo.zoneID, crateInfo.shardID)
    if existing ~= nil then
        local delta = crateInfo.ts - existing.ts
        if delta < 300 and delta > 300 then
            NS.debugPrint("Ignoring announcement from", crateInfo.spotter, "delta is", delta)
            return false
        end
    end
    return true
end

local function announceCrate(crateInfo)
    if shouldAnnounce(crateInfo) and checkDelta(crateInfo) then
        local zoneConfig = NS.zoneConfig[crateInfo.zoneID]
        RaidNotice_AddMessage(RaidWarningFrame, NS.MSG_CRATE_WARN:format(zoneConfig.name, zoneConfig.exp), ChatTypeInfo["RAID_WARNING"]);
        PlaySoundFile("Interface\\AddOns\\WarCrateTracker\\shipswhistle.ogg", "Master")
        print(NS.MSG_CRATE_SPOT:format(zoneConfig.name, zoneConfig.exp, crateInfo.spotter, crateInfo.method.name))
    end
end
NS.announceCrate = announceCrate

local function crateSpotted(vignetteGUID)
    local crateInfo = genCrateInfo(vignetteGUID)
    if crateInfo ~= nil then
        local zoneConfig = NS.zoneConfig[crateInfo.zoneID]
        if zoneConfig == nil then return nil end
        NS.debugPrint("Crate spotted in", zoneConfig.name, "via method", crateInfo.method.name, "- deciding if should be announced")
        if not crateIsDupe(crateInfo) then
            NS.sendCrate(crateInfo, "SPOT_V2")
            announceCrate(crateInfo)
            recordCrate(crateInfo)
        end
    end
end
NS.crateSpotted = crateSpotted

local function warnCrate(crateInfo, curTime)
    local zoneConfig = NS.zoneConfig[crateInfo.zoneID]
    local nextTS = NS.nextCrateTime(crateInfo, curTime)
    if nextTS == nil then
        NS.debugPrint("nexTS was nil???", crateInfo.zoneID, crateInfo.ts, curTime)
        return
    end

    local nextIn = nextTS-curTime
    if nextIn <= 180 then
        local alertKey = format("%i-%i", crateInfo.zoneID, nextTS)
        if NS.alerted[alertKey] == nil then
            RaidNotice_AddMessage(RaidWarningFrame,NS.MSG_CRATE_ALERT:format(zoneConfig.name, zoneConfig.exp, NS.displayTime(nextIn)),ChatTypeInfo["RAID_WARNING"]);
            PlaySound(8232, "Master")
            NS.alerted[alertKey] = true
        end
    end
end
NS.warnCrate = warnCrate
