local addonName, NS = ...

local function updateFrame()
    -- PlaySound(808)
    local curTime = GetServerTime()
    local menuIndex = 1
    local labelText = ""
    local timerText = ""
    for _, k in pairs(NS.sortedZones()) do
        local v = crateDB[k]
        if v ~= nil then
            local zoneInfo = C_Map.GetMapInfo(k)
            if NS.shouldTrack(zoneInfo.parentMapID) then
                local parentInfo = C_Map.GetMapInfo(zoneInfo.parentMapID)
                local nc = nextCrate(k, v, curTime)
                local stale = lastCrateStaleness(k, v, curTime)
                NS.menu[tostring(menuIndex)] = k
                labelText = labelText .. NS.MSG_LABEL:format(menuIndex, parentInfo.name, zoneInfo.name, stale) .. "\n"
                timerText = timerText .. nc .. "\n"
                menuIndex = menuIndex + 1
            end
        end
    end
    if labelText == "" and timerText == "" then
        labelText = "No timers found. Please add zones to\ntracking in settings or wait for a drop."
    end
    NS.mainFrame.labels:SetText(labelText)
    NS.mainFrame.timers:SetText(timerText)
    local w = NS.mainFrame.labels:GetStringWidth() + NS.mainFrame.timers:GetStringWidth()
    local h = NS.mainFrame.labels:GetStringHeight()
    NS.mainFrame:SetSize(w+35, h+50)
end

local function checkTimers()
    local curTime = GetServerTime()
    for k, v in pairs(crateDB) do
        if v ~= nil then
            local zoneInfo = C_Map.GetMapInfo(k)
            if NS.shouldWarn(zoneInfo.parentMapID) then
                local parentInfo = C_Map.GetMapInfo(zoneInfo.parentMapID)
                local nc = nextCrate(k, v, curTime)
                NS.alert(k, v, curTime)
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
                NS.crateAnnounced(npcName, text)
            end
        end
        if npcName == "Malicia" then
            if string.find(text, "Looks like you could all use some resources") then
                NS.crateAnnounced(npcName, text)
            end
        end
        -- if npcName == "Mystic Birdhat" or npcName == "Cousin Slowhands" then
        --         NS.debugPrint(event)
        --         NS.debugPrint(npcName)
        --         NS.debugPrint(text)
        --         crateAnnounced(npcName, text)
        -- end
    elseif event == "PLAYER_TARGET_CHANGED" then
        local name, realm = UnitName("target")
        if name == "War Supply Crate" then
            NS.crateSpotted("target")
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID = ...
        -- print(...)
        -- print(text)
        if prefix == "WarCrateTracker" then
            local zoneID_s, zoneParentID_s, ts_s, announcer = strsplit("~", text)
            local zoneID = tonumber(zoneID_s)
            local zoneParentID = tonumber(zoneParentID_s)
            local ts = tonumber(ts_s)
            NS.doAnnounce(announcer, zoneID, zoneParentID, ts, sender)
        end
    elseif event == "SUPER_TRACKING_CHANGED" then
        local trackableType, trackableID = C_SuperTrack.GetSuperTrackedContent()
        local questID = C_SuperTrack.GetSuperTrackedQuestID()
        local pinType, pinID = C_SuperTrack.GetSuperTrackedMapPin()
        local vignetteGUID = C_SuperTrack.GetSuperTrackedVignette()
        local vignetteInfo = nil
        local name = nil
        local vignetteID = nil
        if vignetteGUID ~= nil then
            vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
            name = vignetteInfo.name
            vignetteID = vignetteInfo.vignetteID
            print("vignetteInfo.type=", vignetteInfo.type)
            print("vignetteInfo.iconWidgetSet=", vignetteInfo.iconWidgetSet)
            print("vignetteInfo.tooltipWidgetSet=", vignetteInfo.tooltipWidgetSet)
            print("vignetteInfo.atlasName=", vignetteInfo.atlasName)
        end
        print("tracking changed", trackableType, trackableID, questID, pinType, pinID, vignetteGUID, vignetteInfo, name, vignetteID)
        if name ~= nil then
            if name == "War Supply Crate" then
                NS.crateSpotted("tracking")
            end
        end
    elseif event == "USER_WAYPOINT_UPDATED" then
        print("USER_WAYPOINT_UPDATED")
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
            NS.configureSettings()

            timer = C_Timer.NewTicker(10, checkTimers)
            if settings["xOfs"] ~= nil and settings["yOfs"] ~= nil then
                NS.mainFrame:SetPoint("CENTER", UIParent, "CENTER", settings["xOfs"], settings["yOfs"])
            end
            if settings["show"] ~= nil and settings["show"] then
                NS.mainFrame:Show()
            end
        end
    elseif event == "PLAYER_LOGOUT" then
        print("Logging out...")
    end
end

NS.mainFrame:SetScript("OnShow", function()
    PlaySound(808)
    if timer ~= nil then
        timer:Cancel()
        timer = C_Timer.NewTicker(1, checkTimers)
    end
    settings["show"] = true
end)

NS.mainFrame:SetScript("OnHide", function()
    PlaySound(808)
    if timer ~= nil then
        timer:Cancel()
        timer = C_Timer.NewTicker(10, checkTimers)
    end
    settings["show"] = false
end)

NS.mainFrame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
NS.mainFrame:RegisterEvent("ADDON_LOADED")
NS.mainFrame:RegisterEvent("PLAYER_LOGOUT")
NS.mainFrame:RegisterEvent("CHAT_MSG_ADDON")
NS.mainFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
NS.mainFrame:RegisterEvent("SUPER_TRACKING_CHANGED")
NS.mainFrame:RegisterEvent("USER_WAYPOINT_UPDATED")
NS.mainFrame:SetScript("OnEvent", OnEvent)
