local addonName, NS = ...

local lastx, lasty = 0, 0
local setupExecuted = false

local function getRemappedZone()
    local zoneID = C_Map.GetBestMapForUnit("player")
    local zoneConfig = NS.zoneConfig[zoneID]
    if zoneConfig ~= nil and zoneConfig.remap ~= nil then
        return zoneConfig.remap
    end
    return zoneID
end

local function updateCurrentShard(guid)
    local zoneID = getRemappedZone()
    if zoneID ~= NS.currentZone then
        NS.currentShard = nil
        NS.currentZone = zoneID
    end
    if guid == nil then
        local vignetteGUIDs = C_VignetteInfo.GetVignettes()
        for _,vignetteGUID in ipairs(vignetteGUIDs) do
            NS.currentShard = NS.getShardFromGUID(vignetteGUID)
            break
        end
    else
        local unitType, _ = strsplit("-", guid, 2)
        if unitType == "Creature" then
            NS.currentShard = NS.getShardFromGUID(guid)
        end
    end
end

local function updateFrame(curTime)
    local menuIndex = 1
    local labelText = ""
    local timerText = ""
    for _, crateKey in pairs(NS.sortedCrateKeys()) do
        local crateInfo = crateDB[crateKey]
        if crateInfo ~= nil then
            if NS.shouldTrack(crateInfo) then
                local zoneConfig = NS.zoneConfig[crateInfo.zoneID]
                local nextCrateText = NS.nextCrateText(crateInfo, curTime)
                local stale = NS.lastCrateStaleness(crateInfo, curTime)
                local color = "";
                if crateInfo.shardID == NS.currentShard then
                    color = "|cff00dd00"
                elseif crateInfo.zoneID ~= NS.currentZone then
                    color = "|cffcccccc"
                end
                if stale <= settings.staleness then
                    NS.menu[tostring(menuIndex)] = crateKey
                    labelText = labelText .. color .. NS.WINDOW_LABEL:format(menuIndex, zoneConfig.exp, zoneConfig.name, crateInfo.shardID, stale) .. "|r\n"
                    timerText = timerText .. color .. NS.WINDOW_TIMER:format(crateInfo.method.abbr, nextCrateText) .. "|r\n"
                    menuIndex = menuIndex + 1
                end
            end
        end

    end
    if NS.currentShard == nil then
        NS.mainFrame.title:SetText("WarCrateTracker - Shard: ?")
    else 
        NS.mainFrame.title:SetText("WarCrateTracker - Shard: " .. NS.currentShard)
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
            if NS.shouldWarn(crateInfo) then
                NS.warnCrate(crateInfo, curTime)
            end
        end
    end
    updateFrame(curTime)
    NS.vignettesUpdated()
end

local function addonLoaded(event, ...)
    local addon = ...
    if addon == "WarCrateTracker" and setupExecuted == false then
        setupExecuted = true
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
        NS.sendAllCrates("REQUEST_V2")
        NS.configureSettings()

        local function setScale()
            if settings["zoneMapScale"] ~= nil then
                BattlefieldMapFrame:SetScale(settings.zoneMapScale/100)
            end
        end

        NS.timer = C_Timer.NewTicker(10, checkTimers)
        if settings["xOfs"] ~= nil and settings["yOfs"] ~= nil then
            NS.mainFrame:SetPoint("CENTER", UIParent, "CENTER", settings["xOfs"], settings["yOfs"])
        end
        if settings["show"] ~= nil and settings["show"] then
            NS.mainFrame:Show()
        end

    end

end

local function chatMsgAddon(event, ...)
    local prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID = ...
    if prefix == "WarCrateTracker" then
        NS.processCrateMessage(text, sender)
    end
end

local function playerEnteringWorld(event, ...)
    if settings["zoneMapScale"] ~= nil then
        if BattlefieldMapFrame ~= nil then
            BattlefieldMapFrame:SetScale(settings.zoneMapScale/100)
        end
    end
end


local function OnEvent(self, event, ...)
    if event == "VIGNETTE_MINIMAP_UPDATED" and NS.vignetteMinimapUpdated ~= nil then
        NS.vignetteMinimapUpdated(event, ...)
        updateCurrentShard()
    elseif event == "VIGNETTES_UPDATED" and NS.vignettesUpdated ~= nil then
        NS.vignettesUpdated(event, ...)
        updateCurrentShard()
    elseif event == "SUPER_TRACKING_CHANGED" then
        NS.superTrackingChanged(event, ...)
        updateCurrentShard()
    elseif event == "CHAT_MSG_ADDON" then
        chatMsgAddon(event, ...)
    elseif event == "ADDON_LOADED" then
        addonLoaded(event, ...)
    elseif event == "PLAYER_ENTERING_WORLD" then
        playerEnteringWorld(event, ...)
        updateCurrentShard()
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        updateCurrentShard(UnitGUID("mouseover"))
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
        updateCurrentShard()
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

NS.mainFrame:RegisterEvent("ADDON_LOADED")
NS.mainFrame:RegisterEvent("CHAT_MSG_ADDON")
NS.mainFrame:RegisterEvent("SUPER_TRACKING_CHANGED")
NS.mainFrame:RegisterEvent("VIGNETTES_UPDATED")
NS.mainFrame:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
NS.mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
NS.mainFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
NS.mainFrame:RegisterEvent("ZONE_CHANGED")
NS.mainFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- These will be added back eventually
-- NS.mainFrame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
-- NS.mainFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

NS.mainFrame:SetScript("OnEvent", OnEvent)
