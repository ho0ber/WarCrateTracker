local addonName, NS = ...


local function compareCrates(k1, k2)
    local curTime = GetServerTime()
    local ts1 = NS.nextCrateTime(crateDB[k1], curTime)
    local ts2 = NS.nextCrateTime(crateDB[k2], curTime)
    if ts1 == nil then
        return false
    elseif ts2 == nil then
        return true
    end
    return ts1 < ts2
end

local function generateKey(zoneID, shardID)
    if zoneID == nil then
        NS.debugPrint("Cannot generate key - zoneID is nil")
        return nil
    end
    if shardID == nil then
        shardID = "nil"
    end
    return zoneID .. "|" .. shardID
end

local function getCrateFromDB(zoneID, shardID)
    if zoneID == nil then
        return nil
    end

    if shardID == nil then
        shardID = "nil"
    end

    local key = generateKey(zoneID, shardID)
    return crateDB[key]
end

local function saveCrateToDB(crateInfo)
    local key = nil
    local zoneConfig = NS.zoneConfig[crateInfo.zoneID]
    if zoneConfig ~= nil and zoneConfig.remap ~= nil then
        key = generateKey(zoneConfig.remap, crateInfo.shardID)
    else 
        key = generateKey(crateInfo.zoneID, crateInfo.shardID)
    end
    NS.debugPrint("key:", key)
    if key ~= nil then
        crateDB[key] = crateInfo
        NS.debugPrint("Saved crate", crateInfo.guid)
    else
        NS.debugPrint("Crate key is nil - cannot save!")
    end
end



local function sortedCrateKeys()
    local keys = {}

    for k, v in pairs(crateDB) do
        if v ~= nil then
            table.insert(keys, k)
        end
    end
    table.sort(keys, compareCrates)
    return keys
end

-- Exports
NS.getCrateFromDB = getCrateFromDB
NS.saveCrateToDB = saveCrateToDB
NS.sortedCrateKeys = sortedCrateKeys
