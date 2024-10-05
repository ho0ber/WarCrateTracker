local addonName, NS = ...

local function displayTime(time)
    local days = floor(time/86400)
    local d_unit = (days > 1 and "days" or "day")
    local hours = floor(mod(time, 86400)/3600)
    local minutes = floor(mod(time,3600)/60)
    local seconds = floor(mod(time,60))
    if days > 0 then
        return format("%d %s %02d hr %02d min %02d sec",days,d_unit,hours,minutes,seconds)
    elseif hours > 0 then
        return format("%02d:%02d:%02d",hours,minutes,seconds)
    elseif minutes > 0 then
        return format("%02d:%02d",minutes,seconds)
    else
        return format("%02d sec",seconds)
    end

    return "Unknown"
end
NS.displayTime = displayTime


local function nextCrateTime(crateInfo, curTime)
    if crateInfo ~= nil then
        local freq = NS.frequency[crateInfo.zoneParentID]
        if freq ~= nil then
            local nextCrateTS = crateInfo.ts
            local duration = curTime-crateInfo.ts
            local crateCount = floor(duration/freq)
            local nextCrateTS = crateInfo.ts+(crateCount+1)*freq
            return nextCrateTS
        end
    end
    return nil
end
NS.nextCrateTime = nextCrateTime


local function lastCrateStaleness(crateInfo, curTime)
    if NS.frequency[crateInfo.zoneParentID] ~= nil then
        local freq = NS.frequency[crateInfo.zoneParentID]
        local duration = curTime-crateInfo.ts
        return floor(duration/freq)
    else
        return nil
    end
end
NS.lastCrateStaleness = lastCrateStaleness

local function nextCrateText(crateInfo, curTime)
    local nc = "Unknown"
    local ts = nextCrateTime(crateInfo, curTime)
    if ts ~= nil then
        nc = tostring(displayTime(ts-curTime))
    else
        nc = format("Unknown: %s (%i) has no frequency configured", crateInfo.zoneParentName, crateInfo.zoneParentID)
    end
    return nc
end
NS.nextCrateText = nextCrateText
