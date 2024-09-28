local recent = {}
local last_timestamp = 0
local debug = true
local alerted = {}
local menu = {}

local MSG_CRATE_WARN = "War Crate in %s - %s"
local MSG_CRATE_ALERT = "War Crate in %s - %s in %s"
local MSG_CRATE = "%s just announced a war crate in %s - %s (heard by %s)"
local MSG_LAST = "%s - %s seen %is ago (%ix)\n  next in %s"
local MSG_NODB = "No previous crate time known for %s"

local MSG_LABEL = "%i. %s - %s (%ix)"
local MSG_TIMER = "%s"

-- type|zoneID|servertime
local ADDON_MSG = "%s|%i|%i|%i|%s"

--sn = strsplit("delimiter", "subject"[, pieces])

local timer = nil

local frequency = {[2274]=1200,[1978]=2700}

local settingsCategoryID = nil

function nextCrateTS(zoneID, last, current)
    local zoneInfo = C_Map.GetMapInfo(zoneID)
    local parentInfo = C_Map.GetMapInfo(zoneInfo.parentMapID)
    if frequency[zoneInfo.parentMapID] ~= nil then
        local freq = frequency[zoneInfo.parentMapID]
        local nextCrateTS = last
        local duration = current-last
        local crateCount = floor(duration/freq)
        local nextCrateTS = last+(crateCount+1)*freq
        return nextCrateTS
    else
        return nil
    end
end

function lastCrateStaleness(zoneID, last, current)
    local zoneInfo = C_Map.GetMapInfo(zoneID)
    if frequency[zoneInfo.parentMapID] ~= nil then
        local freq = frequency[zoneInfo.parentMapID]
        local duration = current-last
        return floor(duration/freq)
    else
        return nil
    end
end

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

function alert(zoneID, last, current)
    -- print("Checking crates for alerts...")
    local nextTS = nextCrateTS(zoneID, last, current)
    local nextIn = nextCrateTS(zoneID, last, current)-current
    if nextIn <= 180 then
        local alertKey = format("%i-%i", zoneID, nextTS)
        if alerted[alertKey] == nil then
            local nextCrateText = nextCrate(zoneID, last, current)
            local zoneName = C_Map.GetMapInfo(zoneID).name
            local zoneParentID = C_Map.GetMapInfo(zoneID).parentMapID
            local zoneParentName = C_Map.GetMapInfo(zoneParentID).name
            RaidNotice_AddMessage(RaidWarningFrame,MSG_CRATE_ALERT:format(zoneName, zoneParentName, nextCrateText),ChatTypeInfo["RAID_WARNING"]);
            PlaySound(8232, "Master")
            alerted[alertKey] = true
        end
        
    end
end

-- function nextCrate(zoneID, last, current)
--     local zoneInfo = C_Map.GetMapInfo(zoneID)
--     local parentInfo = C_Map.GetMapInfo(zoneInfo.parentMapID)
--     local nc = "Unknown" 
--     if frequency[zoneInfo.parentMapID] ~= nil then
--         local freq = frequency[zoneInfo.parentMapID]
--         local nextCrateTS = last
--         local duration = current-last
--         local crateCount = floor(duration/freq)
--         local nextCrateTS = last+(crateCount+1)*freq
--         nc = tostring(disp_time(nextCrateTS-current))
--     else
--         nc = format("Unknown: %s (%i) has no frequency configured", parentInfo.name, zoneInfo.parentMapID)
--     end
--     return nc
-- end

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

local function debugPrint(message)
    if debug then
        print(message)
    end
end

local function shouldAnnounce(zoneParentID)
    return not ((zoneParentID == 2274 and not settings["twwAnnounce"]) or (zoneParentID == 1978 and not settings["dfAnnounce"]))
end

local function shouldTrack(zoneParentID)
    return not ((zoneParentID == 2274 and not settings["twwTrack"]) or (zoneParentID == 1978 and not settings["dfTrack"]))
end

local function shouldWarn(zoneParentID)
    return not ((zoneParentID == 2274 and not settings["twwWarn"]) or (zoneParentID == 1978 and not settings["dfWarn"]))
end

local function sendAnnouncement(zoneID, zoneParentID, curTime, announcer)
    local message = ADDON_MSG:format("ANNOUNCE", zoneID, zoneParentID, curTime, announcer)
    print("sending:",message)
    ChatThrottleLib:SendAddonMessage("NORMAL",  "WarCrateTracker", message, "CHANNEL", "WarCrateTracker");
end

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

        RaidNotice_AddMessage(RaidWarningFrame,MSG_CRATE_WARN:format(zoneName, zoneParentName),ChatTypeInfo["RAID_WARNING"]);
        PlaySoundFile("Interface\\AddOns\\WarCrateTracker\\shipswhistle.ogg", "Master")
        
        print(MSG_CRATE:format(announcer, zoneName, zoneParentName, player))

        local lastTime = crateDB[zoneID]
        if lastTime ~= nil then
            local nc = nextCrate(zoneID, lastTime, ts)
            local stale = lastCrateStaleness(zoneID, lastTime, ts)
            print(MSG_LAST:format(zoneParentName, zoneName, ts-lastTime, stale, nc))
        else
            print(MSG_NODB:format(zoneName))
        end
    end
    crateDB[zoneID] = ts
end

local function crateAnnounced(announcer, text)
    local zoneID = C_Map.GetBestMapForUnit("player")
    local zoneName = C_Map.GetMapInfo(zoneID).name
    local zoneParentID = C_Map.GetMapInfo(zoneID).parentMapID
    local zoneParentName = C_Map.GetMapInfo(zoneParentID).name
    local player = UnitName("player")
    local curTime = GetServerTime()
    

    sendAnnouncement(zoneID, zoneParentID, curTime, announcer)
    doAnnounce(announcer, zoneID, zoneParentID, curTime, player)
    -- if shouldAnnounce(zoneParentID) then
    --     RaidNotice_AddMessage(RaidWarningFrame,MSG_CRATE_WARN:format(zoneName, zoneParentName),ChatTypeInfo["RAID_WARNING"]);
    --     PlaySoundFile("Interface\\AddOns\\WarCrateTracker\\shipswhistle.ogg", "Master")
        
    --     print(MSG_CRATE:format(announcer, zoneName, zoneParentName, player))
    --     if lastTime ~= nil then
    --         local nc = nextCrate(zoneID, lastTime, curTime)
    --         local stale = lastCrateStaleness(zoneID, lastTime, curTime)
    --         print(MSG_LAST:format(zoneParentName, zoneName, curTime-lastTime, stale, nc))
    --     else
    --         print(MSG_NODB:format(zoneName))
    --     end
    -- end
    -- crateDB[zoneID] = curTime
end


local function configureSettings() 
    local category = Settings.RegisterVerticalLayoutCategory("WarCrateTracker")
    
    do
        local variable = "dfAnnounce"
        local name = "Dragon Isles - Announce"
        local tooltip = "Make a sound and announce Dragon Isles crates"
        local variableKey = "dfAnnounce"
        local variableTbl = settings
        local defaultValue = true
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        -- setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    
    do
        local variable = "dfTrack"
        local name = "Dragon Isles - Track"
        local tooltip = "Show Dragon Isles crates in /wct output"
        local variableKey = "dfTrack"
        local variableTbl = settings
        local defaultValue = true
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        -- setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    
    do
        local variable = "dfWarn"
        local name = "Dragon Isles - Warn"
        local tooltip = "Make a sound and warn before Dragon Isles crates will drop"
        local variableKey = "dfWarn"
        local variableTbl = settings
        local defaultValue = true
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        -- setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end


    do
        local variable = "twwAnnounce"
        local name = "Khaz Algar - Announce"
        local tooltip = "Make a sound and announce Khaz Algar crates"
        local variableKey = "twwAnnounce"
        local variableTbl = settings
        local defaultValue = true
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        -- setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    
    do
        local variable = "twwTrack"
        local name = "Khaz Algar - Track"
        local tooltip = "Show Khaz Algar crates in /wct output"
        local variableKey = "twwTrack"
        local variableTbl = settings
        local defaultValue = true
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        -- setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    
    do
        local variable = "twwWarn"
        local name = "Khaz Algar - Warn"
        local tooltip = "Make a sound and warn before Khaz Algar crates will drop"
        local variableKey = "twwWarn"
        local variableTbl = settings
        local defaultValue = true
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        -- setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end


    Settings.RegisterAddOnCategory(category)
    settingsCategoryID = category:GetID()
end

local mainFrame = CreateFrame("Frame", "WarCrateTracker", UIParent, "BasicFrameTemplateWithInset")
mainFrame:SetSize(400, 150)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
mainFrame.TitleBg:SetHeight(30)
mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mainFrame.title:SetPoint("TOPLEFT", mainFrame.TitleBg, "TOPLEFT", 5, -3)
mainFrame.title:SetText("WarCrateTracker")
mainFrame:Hide()
mainFrame:EnableMouse(true)
mainFrame:SetMovable(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)
mainFrame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
    local point, relativeTo, relativePoint, xOfs, yOfs = mainFrame:GetPoint(1)
    settings["xOfs"] = xOfs
    settings["yOfs"] = yOfs
    print(xOfs, yOfs)
end)

local settingsButton = CreateFrame("Button", "Settings", mainFrame)
settingsButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -40, -6)
settingsButton:SetWidth(50)
settingsButton:SetHeight(10)
settingsButton:SetText("Settings")
settingsButton:SetNormalFontObject("GameFontNormalSmall")

settingsButton:SetScript("OnClick", function()
    if settingsCategoryID ~= nil then
        Settings.OpenToCategory(settingsCategoryID)
    end
end)


mainFrame.labels = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.labels:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -35)
mainFrame.labels:SetText("Testing")
mainFrame.labels:SetJustifyH("LEFT")

mainFrame.timers = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mainFrame.timers:SetPoint("LEFT", mainFrame.labels, "RIGHT", 5, 0)
mainFrame.timers:SetText("")
mainFrame.timers:SetJustifyH("LEFT")

local function compareZones(z1, z2)
    local curTime = GetServerTime()
    local ts1 = nextCrateTS(z1, crateDB[z1], curTime)
    local ts2 = nextCrateTS(z2, crateDB[z2], curTime)
    if ts1 == nil then
        return false
    elseif ts2 == nil then
        return true
    end
    return ts1 < ts2
end

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

local function updateFrame()
    -- PlaySound(808)
    local curTime = GetServerTime()
    local menuIndex = 1
    local labelText = ""
    local timerText = ""
    for _, k in pairs(sortedZones()) do
        local v = crateDB[k]
        if v ~= nil then
            local zoneInfo = C_Map.GetMapInfo(k)
            if shouldTrack(zoneInfo.parentMapID) then
                local parentInfo = C_Map.GetMapInfo(zoneInfo.parentMapID)
                local nc = nextCrate(k, v, curTime)
                local stale = lastCrateStaleness(k, v, curTime)
                menu[tostring(menuIndex)] = k
                labelText = labelText .. MSG_LABEL:format(menuIndex, parentInfo.name, zoneInfo.name, stale) .. "\n"
                timerText = timerText .. nc .. "\n"
                menuIndex = menuIndex + 1
            end
        end
    end
    if labelText == "" and timerText == "" then
        labelText = "No timers found. Please add zones to\ntracking in settings or wait for a drop."
    end
    mainFrame.labels:SetText(labelText)
    mainFrame.timers:SetText(timerText)
    local w = mainFrame.labels:GetStringWidth() + mainFrame.timers:GetStringWidth()
    local h = mainFrame.labels:GetStringHeight()
    mainFrame:SetSize(w+35, h+50)
end

local function checkTimers()
    local curTime = GetServerTime()
    for k, v in pairs(crateDB) do
        if v ~= nil then
            local zoneInfo = C_Map.GetMapInfo(k)
            if shouldWarn(zoneInfo.parentMapID) then
                local parentInfo = C_Map.GetMapInfo(zoneInfo.parentMapID)
                local nc = nextCrate(k, v, curTime)
                alert(k, v, curTime)
            end
        end
    end
    updateFrame()
end

local function OnEvent(self, event, ...)
    if event == "CHAT_MSG_MONSTER_SAY" then
        local text, npcName, languageName, channelName, npcName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...
        if npcName == "Ruffious" then
            if string.find(text, "Opportunity's knocking! If you've got the mettle, there are valuables waiting to be won.") or 
                string.find(text, "I see some valuable resources in the area! Get ready to grab them!") or 
                string.find(text, "Looks like there's treasure nearby. And that means treasure hunters. Watch your back.") or
                string.find(text, "There's a cache of resources nearby. Find it before you have to fight over it!") then
                crateAnnounced(npcName, text)
            end
        end
        if npcName == "Malicia" then
            if string.find(text, "Looks like you could all use some resources") then
                crateAnnounced(npcName, text)
            end
        end
        -- if npcName == "Mystic Birdhat" or npcName == "Cousin Slowhands" then
        --         debugPrint(event)
        --         debugPrint(npcName)
        --         debugPrint(text)
        --         crateAnnounced(npcName, text)
        -- end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID = ...
        -- print(...)
        -- print(text)
        if prefix == "WarCrateTracker" then
            local zoneID_s, zoneParentID_s, ts_s, announcer = strsplit("|", text)
            local zoneID = tonumber(zoneID_s)
            local zoneParentID = tonumber(zoneParentID_s)
            local ts = tonumber(ts_s)
            doAnnounce(announcer, zoneID, zoneParentID, ts, sender)
        end

    elseif event == "ADDON_LOADED" then
        local addon = ...
        if addon == "WarCrateTracker" then
            print("WarCrateTracker loaded!")
            if crateDB == nil then
                print("Empty War Crate Database - initializing!")
                crateDB = {}
            end
            if settings == nil then
                print("Empty War Crate Settings - initializing!")
                settings = {}
            end
            configureSettings()


            timer = C_Timer.NewTicker(10, checkTimers)
            if settings["xOfs"] ~= nil and settings["yOfs"] ~= nil then
                mainFrame:SetPoint("CENTER", UIParent, "CENTER", settings["xOfs"], settings["yOfs"])
            end
            if settings["show"] ~= nil and settings["show"] then
                mainFrame:Show()
            end
        end
    elseif event == "PLAYER_LOGOUT" then
        print("Logging out...")
    end
end

mainFrame:SetScript("OnShow", function()
    PlaySound(808)
    if timer ~= nil then
        timer:Cancel()
        timer = C_Timer.NewTicker(1, checkTimers)
    end
    settings["show"] = true
end)

mainFrame:SetScript("OnHide", function()
    PlaySound(808)
    if timer ~= nil then
        timer:Cancel()
        timer = C_Timer.NewTicker(10, checkTimers)
    end
    settings["show"] = false
end)


mainFrame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:RegisterEvent("PLAYER_LOGOUT")
mainFrame:RegisterEvent("CHAT_MSG_ADDON")
mainFrame:SetScript("OnEvent", OnEvent)


local function starts_with(str, start)
    return str:sub(1, #start) == start
end

SLASH_WCT1 = "/wct";
function SlashCmdList.WCT(msg)

    if msg == "clear" then
        crateDB = {}
        print("Cleared crate DB")
    elseif starts_with(msg, "del ") then
        local arg = msg:match("%w+$")
        crateDB[menu[arg]] = nil
    else
        if mainFrame:IsShown() then
            mainFrame:Hide()
        else
            updateFrame()
            mainFrame:Show()
        end
    end
end
