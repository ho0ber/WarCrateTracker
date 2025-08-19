local addonName, NS = ...
local seen_vigs = {}

local function checkVignette(vignetteGUID)
    if vignetteGUID == nil or seen_vigs[vignetteGUID] ~= nil then
        return false
    end

    seen_vigs[vignetteGUID] = true

    local vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
    if vignetteInfo ~= nil and vignetteInfo.name == "War Supply Crate" then
        method = NS.crateVignetteIDs[vignetteInfo.vignetteID]
        if method ~= nil then
            NS.crateSpotted(vignetteGUID)
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
    local vignetteGUID = C_SuperTrack.GetSuperTrackedVignette()
    checkVignette(vignetteGUID)
end
