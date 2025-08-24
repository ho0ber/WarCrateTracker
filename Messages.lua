local addonName, NS = ...

local function sendCrate(crateInfo, sendType)
    local zoneConfig = NS.zoneConfig[crateInfo.zoneID]
    local zoneInfo = C_Map.GetMapInfo(crateInfo.zoneID)
    local zoneParentID = zoneInfo.parentMapID
    local zoneParentName = C_Map.GetMapInfo(zoneParentID).name
    if sendType == "SPOT_V2" or sendType == "REQUEST_V2" or sendType == "UPDATE_V2" then
        local message = strjoin("~", sendType, tostring(crateInfo.method.vignetteID), tostring(crateInfo.ts), tostring(crateInfo.zoneID), crateInfo.spotter, crateInfo.shardID, crateInfo.guid)
        NS.debugPrint("sending:",message)
        ChatThrottleLib:SendAddonMessage("NORMAL",  "WarCrateTracker", message, "GUILD") --"CHANNEL", "WarCrateTracker");
        ChatThrottleLib:SendAddonMessage("NORMAL",  "WarCrateTracker", message, "PARTY")
    -- else
        -- NS.debugPrint("Skipping send of old style message")
        -- local message = strjoin("~", sendType, crateInfo.method, tostring(crateInfo.ts), tostring(crateInfo.zoneID), tostring(zoneParentID), zoneConfig.name, zoneParentName, crateInfo.spotter)
        -- NS.debugPrint("sending:",message)
        -- ChatThrottleLib:SendAddonMessage("NORMAL",  "WarCrateTracker", message, "GUILD") --"CHANNEL", "WarCrateTracker");
        -- ChatThrottleLib:SendAddonMessage("NORMAL",  "WarCrateTracker", message, "PARTY")
    end
end
NS.sendCrate = sendCrate

local function processCrateMessage(text, sender)
    local senderName, senderRealm = strsplit("-", sender, 2)
    local playerName, playerRealm = UnitFullName("player")
    if senderName == playerName and senderRealm == playerRealm then
        -- NS.debugPrint("Ignoring a message from myself:",sender,text)
        return
    end

    local sendType, _ = strsplit("~", text, 2)
    local crateInfo = nil
    if sendType == "SPOT_V2" or sendType == "REQUEST_V2" or sendType == "UPDATE_V2" then
        local _, method_id, ts_s, zoneID_s, spotter, shardID, guid = strsplit("~", text)
        local method = NS.crateVignetteIDs[tonumber(method_id)]
        crateInfo = {
            guid=guid,
            method=method,
            ts=tonumber(ts_s),
            zoneID=tonumber(zoneID_s),
            shardID=shardID,
            spotter=spotter
        }
    else
        local _, method, ts_s, zoneID_s, zoneParentID_s, zoneName, zoneParentName, spotter = strsplit("~", text)
        local shardID, guid = "unknown", "unknown"
        crateInfo = {
            guid=guid,
            method={name=method},
            ts=tonumber(ts_s),
            zoneID=tonumber(zoneID_s),
            shardID=shardID,
            spotter=spotter
        }
    end

    -- NS.debugPrint("Recieved addon message from", sender, "-", text)
    if sendType == "SPOT_V2" then
        NS.announceCrate(crateInfo)
        NS.recordCrate(crateInfo)
    elseif sendType == "REQUEST_V2" then
        NS.recordCrate(crateInfo)
        NS.debugPrint("Heard REQUEST_V2 message - responding with our crateDB data")
        NS.sendAllCrates("UPDATE_V2")
    elseif sendType == "UPDATE_V2" then
        NS.recordCrate(crateInfo)
    elseif sendType == "SPOT" then
        NS.announceCrate(crateInfo)
        -- recordCrate(crateInfo)
    -- elseif sendType == "LOGIN" then
    --     recordCrate(crateInfo)
    --     NS.debugPrint("Heard LOGIN message - responding with our crateDB data")
    --     sendAllCrates("UPDATE")
    -- elseif sendType == "UPDATE" then
    --     recordCrate(crateInfo)
    end
end
NS.processCrateMessage = processCrateMessage
