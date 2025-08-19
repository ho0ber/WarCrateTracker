local addonName, NS = ...

local function sendCrate(crateInfo, sendType)
    -- local message = strjoin("~", sendType, crateInfo.method, tostring(crateInfo.ts), tostring(crateInfo.zoneID), tostring(crateInfo.zoneParentID), crateInfo.zoneName, crateInfo.zoneParentName, crateInfo.spotter)
    -- NS.debugPrint("sending:",message)
    -- ChatThrottleLib:SendAddonMessage("NORMAL",  "WarCrateTracker", message, "GUILD") --"CHANNEL", "WarCrateTracker");
    -- ChatThrottleLib:SendAddonMessage("NORMAL",  "WarCrateTracker", message, "PARTY")
    NS.debugPrint("Skipping crate send because of rewrite")
end
NS.sendCrate = sendCrate

local function processCrateMessage(text, sender)
    NS.debugPrint("Ignoring crate message because of rewrite")
    -- local senderName, senderRealm = strsplit("-", sender, 2)
    -- local playerName, playerRealm = UnitFullName("player")
    -- if senderName == playerName and senderRealm == playerRealm then
    --     NS.debugPrint("Ignoring a message from myself:",sender,text)
    --     return
    -- end
    -- local sendType, method, ts_s, zoneID_s, zoneParentID_s, zoneName, zoneParentName, spotter = strsplit("~", text)
    -- local crateInfo = {method=method, ts=tonumber(ts_s), zoneID=tonumber(zoneID_s), zoneParentID=tonumber(zoneParentID_s), zoneName=zoneName, zoneParentName=zoneParentName, spotter=spotter}
    -- NS.debugPrint("Recieved addon message from", sender, "-", text)
    -- if sendType == "SPOT" then
    --     announceCrate(crateInfo)
    --     recordCrate(crateInfo)
    -- elseif sendType == "LOGIN" then
    --     recordCrate(crateInfo)
    --     NS.debugPrint("Heard LOGIN message - responding with our crateDB data")
    --     sendAllCrates("UPDATE")
    -- elseif sendType == "UPDATE" then
    --     recordCrate(crateInfo)
    -- end
end
NS.processCrateMessage = processCrateMessage
