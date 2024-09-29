local addonName, NS = ...

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
        crateDB[NS.menu[arg]] = nil
    elseif msg == "spot" then
        NS.crateSpotted("manual")
    else
        if NS.mainFrame:IsShown() then
            NS.mainFrame:Hide()
        else
            NS.updateFrame()
            NS.mainFrame:Show()
        end
    end
end
