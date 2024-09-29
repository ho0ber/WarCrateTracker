local addonName, NS = ...

NS.mainFrame = CreateFrame("Frame", "WarCrateTracker", UIParent, "BasicFrameTemplateWithInset")
NS.mainFrame:SetSize(400, 150)
NS.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
NS.mainFrame.TitleBg:SetHeight(30)
NS.mainFrame.title = NS.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
NS.mainFrame.title:SetPoint("TOPLEFT", NS.mainFrame.TitleBg, "TOPLEFT", 5, -3)
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
    print(xOfs, yOfs)
end)

NS.settingsButton = CreateFrame("Button", "Settings", NS.mainFrame)
NS.settingsButton:SetPoint("TOPRIGHT", NS.mainFrame, "TOPRIGHT", -40, -6)
NS.settingsButton:SetWidth(50)
NS.settingsButton:SetHeight(10)
NS.settingsButton:SetText("Settings")
NS.settingsButton:SetNormalFontObject("GameFontNormalSmall")

NS.settingsButton:SetScript("OnClick", function()
    if NS.settingsCategoryID ~= nil then
        Settings.OpenToCategory(NS.settingsCategoryID)
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
