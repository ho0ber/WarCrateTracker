local addonName, NS = ...

local function updateFrame(curTime)
    -- PlaySound(808)
    local menuIndex = 1
    local labelText = ""
    local timerText = ""
    for _, zoneID in pairs(NS.sortedZones()) do
        local crateInfo = crateDB[zoneID]
        if crateInfo ~= nil then
            if NS.shouldTrack(crateInfo.zoneParentID) then
                local nextCrateText = NS.nextCrateText(crateInfo, curTime)
                local stale = NS.lastCrateStaleness(crateInfo, curTime)
                NS.menu[tostring(menuIndex)] = crateInfo.zoneID
                labelText = labelText .. NS.WINDOW_LABEL:format(menuIndex, crateInfo.zoneParentName, crateInfo.zoneName, stale) .. "\n"
                timerText = timerText .. NS.WINDOW_TIMER:format(NS.abbreviateMethod(crateInfo), nextCrateText) .. "\n"
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
    for _, crateInfo in pairs(crateDB) do
        if crateInfo ~= nil then
            if NS.shouldWarn(crateInfo.zoneParentID) then
                NS.warnCrate(crateInfo, curTime)
            end
        end
    end
    updateFrame(curTime)
end

local function findMethod(vignetteID)
    if vignetteID == 3689 then -- plane
        return "plane"
    elseif vignetteID == 2967 then -- falling crate
        return "parachute"
    elseif vignetteID == 6066 then -- unclaimed crate on ground
        return "unclaimed"
    elseif vignetteID == 6068 then -- claimed faction crate
        return "claimed"
    end
    return nil
end

local function OnEvent(self, event, ...)
    if event == "CHAT_MSG_MONSTER_SAY" then
        local text, npcName, languageName, channelName, npcName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...
        if npcName == "Ruffious" then
            if string.find(text, "Opportunity's knocking! If you've got the mettle, there are valuables waiting to be won.") or 
                string.find(text, "I see some valuable resources in the area! Get ready to grab them!") or 
                string.find(text, "Looks like there's treasure nearby. And that means treasure hunters. Watch your back.") or
                string.find(text, "There's a cache of resources nearby. Find it before you have to fight over it!") then
                NS.crateSpotted("heard")
            end
        end
        if npcName == "Malicia" then
            if string.find(text, "Looks like you could all use some resources") then
                NS.crateSpotted("heard")
            end
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID = ...
        if prefix == "WarCrateTracker" then
            NS.processCrateMessage(text, sender)
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
                if vignetteInfo.name == "War Supply Crate" then
                    local method = findMethod(vignetteInfo.vignetteID)
                    if method ~= nil then
                        NS.crateSpotted(method)
                    end
                end
            end
        end
    elseif event == "VIGNETTES_UPDATED" then
        local vignetteGUIDs = C_VignetteInfo.GetVignettes()
        for k,v in pairs(vignetteGUIDs) do
            if NS.seenVignetteGUIDs[k] ~= true then
                NS.seenVignetteGUIDs[k] = true
                local vignetteInfo = C_VignetteInfo.GetVignetteInfo(v)
                if vignetteInfo ~= nil and vignetteInfo.name == "War Supply Crate" then
                    local method = findMethod(vignetteInfo.vignetteID)
                    if method ~= nil then
                        NS.crateSpotted(method)
                    end
                end
            end
        end
    elseif event == "ADDON_LOADED" then
        local addon = ...
        if addon == "WarCrateTracker" then
            print("WarCrateTracker loaded! /wct to toggle window")
            C_ChatInfo.RegisterAddonMessagePrefix("WarCrateTracker")
            if crateDB == nil then
                NS.debugPrint("Empty War Crate Database - initializing!")
                crateDB = {}
            end
            if settings == nil then
                NS.debugPrint("Empty War Crate Settings - initializing!")
                settings = {}
            end
            NS.convertDB()
            NS.sendAllCrates("LOGIN")
            NS.configureSettings()

            NS.timer = C_Timer.NewTicker(10, checkTimers)
            if settings["xOfs"] ~= nil and settings["yOfs"] ~= nil then
                NS.mainFrame:SetPoint("CENTER", UIParent, "CENTER", settings["xOfs"], settings["yOfs"])
            end
            if settings["show"] ~= nil and settings["show"] then
                NS.mainFrame:Show()
            end
        end
    elseif event == "PLAYER_LOGOUT" then
        NS.debugPrint("Logging out...")
    end
end

NS.mainFrame:SetScript("OnShow", function()
    PlaySound(808)
    if NS.timer ~= nil then
        NS.timer:Cancel()
        NS.timer = C_Timer.NewTicker(1, checkTimers)
    end
    settings["show"] = true
end)

NS.mainFrame:SetScript("OnHide", function()
    PlaySound(808)
    if NS.timer ~= nil then
        NS.timer:Cancel()
        NS.timer = C_Timer.NewTicker(10, checkTimers)
    end
    settings["show"] = false
end)

NS.mainFrame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
NS.mainFrame:RegisterEvent("ADDON_LOADED")
NS.mainFrame:RegisterEvent("PLAYER_LOGOUT")
NS.mainFrame:RegisterEvent("CHAT_MSG_ADDON")
NS.mainFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
NS.mainFrame:RegisterEvent("SUPER_TRACKING_CHANGED")
NS.mainFrame:RegisterEvent("VIGNETTES_UPDATED")
NS.mainFrame:SetScript("OnEvent", OnEvent)
