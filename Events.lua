local addonName, NS = ...

local lastx, lasty = 0, 0
local setupExecuted = false

local function updateFrame(curTime)
    -- PlaySound(808)
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
                if stale <= settings.staleness then
                    NS.menu[tostring(menuIndex)] = crateKey
                    labelText = labelText .. NS.WINDOW_LABEL:format(menuIndex, zoneConfig.exp, zoneConfig.name, crateInfo.shardID, stale) .. "\n"
                    timerText = timerText .. NS.WINDOW_TIMER:format(crateInfo.method.abbr, nextCrateText) .. "\n"
                    menuIndex = menuIndex + 1
                end
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
            if NS.shouldWarn(crateInfo) then
                NS.warnCrate(crateInfo, curTime)
            end
        end
    end
    updateFrame(curTime)
    NS.vignettesUpdated()
end


local function OnEvent(self, event, ...)
    if event == "VIGNETTE_MINIMAP_UPDATED" and NS.vignetteMinimapUpdated ~= nil then
        NS.vignetteMinimapUpdated(event, ...)
    elseif event == "VIGNETTES_UPDATED" and NS.vignettesUpdated ~= nil then
        NS.vignettesUpdated(event, ...)
    elseif event == "SUPER_TRACKING_CHANGED" then
        NS.superTrackingChanged(event, ...)
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID = ...
        if prefix == "WarCrateTracker" then
            NS.processCrateMessage(text, sender)
        end
    elseif event == "ADDON_LOADED" then
        local addon = ...
        if addon == "WarCrateTracker" and setupExecuted == false then
            setupExecuted = true
            print("WarCrateTracker loaded! /wct to toggle window")
            C_ChatInfo.RegisterAddonMessagePrefix("WarCrateTracker")
            -- crateDB = nil
            if crateDB == nil then
                NS.debugPrint("Empty War Crate Database - initializing!")
                crateDB = {}
            end
            if settings == nil then
                NS.debugPrint("Empty War Crate Settings - initializing!")
                settings = {}
            end
            -- NS.convertDB()
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
    elseif event == "PLAYER_LOGOUT" then
        NS.debugPrint("Logging out...")
    elseif event == "PLAYER_ENTERING_WORLD" then
        if settings["zoneMapScale"] ~= nil then
            if BattlefieldMapFrame ~= nil then
                BattlefieldMapFrame:SetScale(settings.zoneMapScale/100)
            end
        end
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
-- NS.mainFrame:RegisterEvent("CHAT_MSG_MONSTER_SAY")
-- NS.mainFrame:RegisterEvent("PLAYER_LOGOUT")
-- NS.mainFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

NS.mainFrame:RegisterEvent("SUPER_TRACKING_CHANGED")
NS.mainFrame:RegisterEvent("VIGNETTES_UPDATED")
NS.mainFrame:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
NS.mainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

NS.mainFrame:SetScript("OnEvent", OnEvent)
