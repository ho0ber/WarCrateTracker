local addonName, NS = ...

NS.mainFrame = CreateFrame("Frame", "WarCrateTracker", UIParent, "BasicFrameTemplateWithInset")
NS.mainFrame:SetSize(400, 150)
NS.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
NS.mainFrame.TitleBg:SetHeight(30)
NS.mainFrame.title = NS.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
NS.mainFrame.title:SetPoint("TOPLEFT", NS.mainFrame.TitleBg, "TOPLEFT", 5, -4)
NS.mainFrame.title:SetText("WarCrateTracker")
NS.mainFrame:Hide()
NS.mainFrame:EnableMouse(true)
NS.mainFrame:SetMovable(true)
NS.mainFrame:RegisterForDrag("LeftButton")
NS.mainFrame:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)
NS.mainFrame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
    local point, relativeTo, relativePoint, xOfs, yOfs = NS.mainFrame:GetPoint(1)
    settings["xOfs"] = xOfs
    settings["yOfs"] = yOfs
    NS.debugPrint(xOfs, yOfs)
end)

NS.settingsButton = CreateFrame("Button", "Settings", NS.mainFrame)
NS.settingsButton:SetPoint("TOPRIGHT", NS.mainFrame, "TOPRIGHT", -22, 0)
local t = NS.settingsButton:CreateTexture()
t:SetAtlas("UI-QuestTrackerButton-Filter", false)
local tp = NS.settingsButton:CreateTexture()
tp:SetAtlas("UI-QuestTrackerButton-Filter-Pressed", false)
NS.settingsButton:SetNormalTexture(t)
NS.settingsButton:SetPushedTexture(tp)
NS.settingsButton:SetWidth(24)
NS.settingsButton:SetHeight(24)
NS.settingsButton:SetNormalFontObject("GameFontNormalSmall")

NS.settingsButton:SetScript("OnClick", function()
    if NS.settingsCategoryID ~= nil then
        Settings.OpenToCategory(NS.settingsCategoryID)
    end
end)

NS.syncButton = CreateFrame("Button", "Sync", NS.mainFrame)
NS.syncButton:SetPoint("RIGHT", NS.settingsButton, "LEFT", 3, 0)
local t2 = NS.syncButton:CreateTexture()
t2:SetAtlas("RedButton-Expand", false)
local t2p = NS.syncButton:CreateTexture()
t2p:SetAtlas("RedButton-Expand-Pressed", false)
NS.syncButton:SetNormalTexture(t2)
NS.syncButton:SetPushedTexture(t2p)
NS.syncButton:SetWidth(24)
NS.syncButton:SetHeight(24)
NS.syncButton:SetNormalFontObject("GameFontNormalSmall")

NS.syncButton:SetScript("OnClick", function()
    NS.sendAllCrates("REQUEST_V2")
end)


NS.seenButton = CreateFrame("Button", "Seen", NS.mainFrame)
NS.seenButton:SetPoint("RIGHT", NS.syncButton, "LEFT", 0, 0)
local t3 = NS.seenButton:CreateTexture()
local t3p = NS.seenButton:CreateTexture()
t3:SetAtlas("GM-icon-visible", false)
t3p:SetAtlas("GM-icon-visible-pressed", false)
NS.t3 = t3
NS.t3p = t3p

t3:SetAtlas("GM-icon-visibleDis", false)
t3p:SetAtlas("GM-icon-visibleDis-pressed", false)
NS.seenButton:SetNormalTexture(t3)
NS.seenButton:SetPushedTexture(t3p)
NS.seenButton:SetWidth(24)
NS.seenButton:SetHeight(24)
NS.seenButton:SetNormalFontObject("GameFontNormalSmall")

NS.seenButton:SetScript("OnClick", function()
    if not settings.lastSeenOnly then
        settings.lastSeenOnly = true
        t3:SetAtlas("GM-icon-visible", false)
        t3p:SetAtlas("GM-icon-visible-pressed", false)
    else
        settings.lastSeenOnly = false
        t3:SetAtlas("GM-icon-visibleDis", false)
        t3p:SetAtlas("GM-icon-visibleDis-pressed", false)
    end
end)



NS.mainFrame.labels = NS.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
NS.mainFrame.labels:SetPoint("TOPLEFT", NS.mainFrame, "TOPLEFT", 15, -35)
NS.mainFrame.labels:SetText("Testing")
NS.mainFrame.labels:SetJustifyH("LEFT")

NS.mainFrame.timers = NS.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
NS.mainFrame.timers:SetPoint("LEFT", NS.mainFrame.labels, "RIGHT", 5, 0)
NS.mainFrame.timers:SetText("")
NS.mainFrame.timers:SetJustifyH("LEFT")
