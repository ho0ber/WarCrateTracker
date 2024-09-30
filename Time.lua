local addonName, NS = ...

function disp_time(time)
    local days = floor(time/86400)
    local d_unit = (days > 1 and "days" or "day")
    local hours = floor(mod(time, 86400)/3600)
    local minutes = floor(mod(time,3600)/60)
    local seconds = floor(mod(time,60))
    if days > 0 then
        return format("%d %s %02d hr %02d min %02d sec",days,d_unit,hours,minutes,seconds)
    elseif hours > 0 then
        return format("%02d hr %02d min %02d sec",hours,minutes,seconds)
    elseif minutes > 0 then
        return format("%02d min %02d sec",minutes,seconds)
    else
        return format("%02d seconds",seconds)
    end

    return "Unknown"
end
NS.disp_time = disp_time

function nextCrateTS(zoneID, last, current)
    local zoneInfo = C_Map.GetMapInfo(zoneID)
    local parentInfo = C_Map.GetMapInfo(zoneInfo.parentMapID)
    if NS.frequency[zoneInfo.parentMapID] ~= nil then
        local freq = NS.frequency[zoneInfo.parentMapID]
        local nextCrateTS = last
        local duration = current-last
        local crateCount = floor(duration/freq)
        local nextCrateTS = last+(crateCount+1)*freq
        return nextCrateTS
    else
        print("didn't find a frequency for", zoneInfo.parentMapID)
        return 0
    end
end
NS.nextCrateTS = nextCrateTS

function lastCrateStaleness(zoneID, last, current)
    local zoneInfo = C_Map.GetMapInfo(zoneID)
    if NS.frequency[zoneInfo.parentMapID] ~= nil then
        local freq = NS.frequency[zoneInfo.parentMapID]
        local duration = current-last
        return floor(duration/freq)
    else
        return nil
    end
end
NS.lastCrateStaleness = lastCrateStaleness

function nextCrate(zoneID, last, current)
    local zoneInfo = C_Map.GetMapInfo(zoneID)
    local parentInfo = C_Map.GetMapInfo(zoneInfo.parentMapID)
    local nc = "Unknown"
    local ts = nextCrateTS(zoneID, last, current)
    if ts ~= nil then
        nc = tostring(disp_time(ts-current))
    else
        nc = format("Unknown: %s (%i) has no frequency configured", parentInfo.name, zoneInfo.parentMapID)
    end
    return nc
end
NS.nextCrate = nextCrate
