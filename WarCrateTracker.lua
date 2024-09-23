local recent = {}
local last_timestamp = 0
local debug = true

local MSG_CRATE_WARN = "War Crate in %s - %s"
local MSG_CRATE = "%s just announced a war crate in %s - %s (heard by %s)"
local MSG_LAST = "Last crate in %s - %s was seen %i seconds ago, next crate in %s"
local MSG_NODB = "No previous crate time known for %s"

local frequency = {[2274]=1200,[1978]=2700}

function nextCrate(zoneID, last, current)
    local zoneInfo = C_Map.GetMapInfo(zoneID)
    local parentInfo = C_Map.GetMapInfo(zoneInfo.parentMapID)
    local nc = "Unknown"
    if frequency[zoneInfo.parentMapID] ~= nil then
        local freq = frequency[zoneInfo.parentMapID]
        local nextCrateTS = last
        local duration = current-last
        local crateCount = floor(duration/freq)
        local nextCrateTS = last+(crateCount+1)*freq
        nc = tostring(disp_time(nextCrateTS-current))
    else
        nc = format("Unknown: %s (%i) has no frequency configured", parentInfo.name, zoneInfo.parentMapID)
    end
    return nc
end

function disp_time(time)
    local days = floor(time/86400)
    local d_unit = (days > 1 and "days" or "day")
    local hours = floor(mod(time, 86400)/3600)
    local minutes = floor(mod(time,3600)/60)
    local seconds = floor(mod(time,60))
    if days > 0 and hours > 0 and minutes > 0 and seconds > 0 then
        return format("%d %s %02d hr %02d min %02d sec",days,d_unit,hours,minutes,seconds)
    elseif hours > 0 and minutes > 0 and seconds > 0 then
        return format("%02d hr %02d min %02d sec",hours,minutes,seconds)
    elseif minutes > 0 and seconds > 0 then
        return format("%02d min %02d sec",minutes,seconds)
    else
        return format("%02d seconds",seconds)
    end

    return "Unknown"
end

local function debugPrint(message)
    if debug then
        print(message)
    end
end

local function crateAnnounced(announcer, text)
    local zoneID = C_Map.GetBestMapForUnit("player")
    local zoneName = C_Map.GetMapInfo(zoneID).name
    local zoneParentID = C_Map.GetMapInfo(zoneID).parentMapID
    local zoneParentName = C_Map.GetMapInfo(zoneParentID).name
    local player = UnitName("player")
    local curTime = GetServerTime()
    local lastTime = crateDB[zoneID]
    RaidNotice_AddMessage(RaidWarningFrame,MSG_CRATE_WARN:format(zoneName, zoneParentName),ChatTypeInfo["RAID_WARNING"]);
    PlaySoundFile("Interface\\AddOns\\WarCrateTracker\\shipswhistle.ogg", "Master")
    
    print(MSG_CRATE:format(announcer, zoneName, zoneParentName, player))
    if lastTime ~= nil then
        local nc = nextCrate(zoneID, lastTime, curTime)
        print(MSG_LAST:format(zoneParentName, zoneName, curTime-lastTime, nc))
    else
        print(MSG_NODB:format(zoneName))
    end
    crateDB[zoneID] = curTime
end

local function OnEvent(self, event, ...)
    if event == "CHAT_MSG_MONSTER_SAY" then
        local text, npcName, languageName, channelName, npcName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...
        if npcName == "Ruffious" then
            print("Heard something!")
            if string.find(text, "Opportunity's knocking! If you've got the mettle, there are valuables waiting to be won.") or 
                string.find(text, "I see some valuable resources in the area! Get ready to grab them!") or 
                string.find(text, "Looks like there's treasure nearby. And that means treasure hunters. Watch your back.") or
                string.find(text, "There's a cache of resources nearby. Find it before you have to fight over it!") then
                crateAnnounced(npcName, text)
            end
        end
        if npcName == "Malicia" then
            --Looks like you could all use some resources. Hmm, there's a saying for this-- survival of the fittest.
            crateAnnounced(npcName, text)
        end
        if npcName == "Mystic Birdhat" or npcName == "Cousin Slowhands" then
                debugPrint(event)
                debugPrint(npcName)
                debugPrint(text)
                crateAnnounced(npcName, text)
        end
    elseif event == "ADDON_LOADED" then
        addon = ...
        if addon == "WarCrateTracker" then
            print("WarCrateTracker loaded!")
            if crateDB == nil then
                print("Empty War Crate Database - initializing!")
                crateDB = {}
            end
        end
    elseif event == "PLAYER_LOGOUT" then
        print("Logging out...")
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_MONSTER_SAY")
f:RegisterEvent("ADDON_LOADED");
f:RegisterEvent("PLAYER_LOGOUT");
f:SetScript("OnEvent", OnEvent)

SLASH_WCT1 = "/wct";
function SlashCmdList.WCT(msg)
    if msg == "clear" then
        crateDB = {}
        print("Cleared crate DB")
    else
        local curTime = GetServerTime()
        print("War crates:")
        for k, v in pairs(crateDB) do
            local zoneInfo = C_Map.GetMapInfo(k)
            local parentInfo = C_Map.GetMapInfo(zoneInfo.parentMapID)
            local nc = nextCrate(k, v, curTime)
            print(MSG_LAST:format(parentInfo.name, zoneInfo.name, curTime-v, nc))
        end
    end
end

