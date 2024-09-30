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
NS.updateFrame = updateFrame

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
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID = ...
        if prefix == "WarCrateTracker" then
            local zoneID_s, zoneParentID_s, ts_s, announcer = strsplit("~", text)
            local zoneID = tonumber(zoneID_s)
            local zoneParentID = tonumber(zoneParentID_s)
            local ts = tonumber(ts_s)
            NS.doAnnounce(announcer, zoneID, zoneParentID, ts, sender)
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        local name, realm = UnitName("target")
        if name == "War Supply Crate" then
            NS.crateSpotted("target")
        end
    elseif event == "SUPER_TRACKING_CHANGED" then
        local vignetteGUID = C_SuperTrack.GetSuperTrackedVignette()
        if vignetteGUID ~= nil then
            local vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
            if vignetteInfo ~= nil then
                print("vignetteInfo.name=", vignetteInfo.name)
                print("vignetteInfo.vignetteID=", vignetteInfo.vignetteID)
                print("vignetteInfo.atlasName=", vignetteInfo.atlasName)
                if vignetteInfo.name == "War Supply Crate" then
                    if vignetteInfo.vignetteID == 3689 then -- plane
                        NS.crateSpotted("track-plane")
                    elseif vignetteInfo.vignetteID == 2967 then -- falling crate
                        NS.crateSpotted("track-parachute")
                    elseif vignetteInfo.vignetteID == 6066 then -- unclaimed crate on ground
                        NS.crateSpotted("track-unclaimed")
                    elseif vignetteInfo.vignetteID == 6068 then -- claimed faction crate
                        NS.crateSpotted("track-claimed")
                    end
                end
            end
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
NS.mainFrame:SetScript("OnEvent", OnEvent)
