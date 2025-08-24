local addonName, NS = ...
local seen_vigs = {}
local lastx, lasty = nil, nil
local lastGUID = nil
local MEASURE_DELAY = 0.5


local function getPosition(vignetteGUID)
    if vignetteGUID == nil then
        return nil, nil
    end

    local vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
    local zoneID = C_Map.GetBestMapForUnit("player")
    if vignetteInfo == nil or zoneID == nil then
        return nil, nil
    end 

    local vignettePosition, _ = C_VignetteInfo.GetVignettePosition(vignetteGUID, zoneID)
    if vignettePosition == nil then
        return nil, nil
    end

    return vignettePosition:GetXY()
end

NS.checkForMovement = nil
local function checkForMovement()
    local x, y = getPosition(lastGUID)
    if x == nil or y == nil or lastx == nil or lasty == nil then
        return
    end
    xdelta = x-lastx
    ydelta = y-lasty

    if xdelta ~= 0 or ydelta ~= 0 then
        NS.crateSpotted(lastGUID)
    else
        NS.debugPrint("Position of", strsub(lastGUID, -5), "unchanged... waiting", MEASURE_DELAY, "to get position...")
        C_Timer.After(MEASURE_DELAY, NS.checkForMovement)
    end
end
NS.checkForMovement = checkForMovement

local function spotOnceMoved()
    local x, y = getPosition(lastGUID)
    if x == nil or y == nil then
        return
    end
    lastx = x
    lasty = y

    NS.debugPrint("Got position 1 for", strsub(lastGUID, -5), "waiting", MEASURE_DELAY, "to get position...")
    C_Timer.After(MEASURE_DELAY, checkForMovement)
end
NS.spotOnceMoved = spotOnceMoved



local function checkVignette(vignetteGUID)
    if vignetteGUID == nil or seen_vigs[vignetteGUID] ~= nil then
        return false
    end

    seen_vigs[vignetteGUID] = true

    local vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
    if vignetteInfo ~= nil and vignetteInfo.name == "War Supply Crate" then
        method = NS.crateVignetteIDs[vignetteInfo.vignetteID]
        if method ~= nil then
            if method.name == "plane" then
                lastx, lasty = nil, nil
                lastGUID = vignetteGUID
                C_Timer.After(MEASURE_DELAY, NS.spotOnceMoved)
            else
                NS.crateSpotted(vignetteGUID)
            end
        else
            NS.debugPrint("Vignette didn't match a method:", vignetteGUID, "has vignetteID", vignetteInfo.vignetteID)
        end
    end
end

local function vignetteMinimapUpdated(event, ...) 
    local vignetteGUID, onMinimap = ...
    checkVignette(vignetteGUID)
end
NS.vignetteMinimapUpdated = vignetteMinimapUpdated

local function vignettesUpdated(event, ...)
    local vignetteGUIDs = C_VignetteInfo.GetVignettes()
    for _,vignetteGUID in ipairs(vignetteGUIDs) do
        checkVignette(vignetteGUID)
    end
end
NS.vignettesUpdated = vignettesUpdated

local function superTrackingChanged(event, ...)
    seen_vigs = {}
    local vignetteGUID = C_SuperTrack.GetSuperTrackedVignette()
    checkVignette(vignetteGUID)
end
NS.superTrackingChanged = superTrackingChanged
