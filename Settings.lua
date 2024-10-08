local addonName, NS = ...

local function updateMuteBounty()
    if settings.muteBounty ~= true then
        UnmuteSoundFile(53225)
    else
        MuteSoundFile(53225)
    end
end

local function configureSettings() 
    updateMuteBounty() --so when we load the addon it applies the setting

    local category = Settings.RegisterVerticalLayoutCategory("WarCrateTracker")
    
    do
        local variable = "dfAnnounce"
        local name = "Dragon Isles - Announce"
        local tooltip = "Make a sound and announce Dragon Isles crates"
        local variableKey = "dfAnnounce"
        local variableTbl = settings
        local defaultValue = true
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        -- setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    
    do
        local variable = "dfTrack"
        local name = "Dragon Isles - Track"
        local tooltip = "Show Dragon Isles crates in /wct output"
        local variableKey = "dfTrack"
        local variableTbl = settings
        local defaultValue = true
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        -- setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    
    do
        local variable = "dfWarn"
        local name = "Dragon Isles - Warn"
        local tooltip = "Make a sound and warn before Dragon Isles crates will drop"
        local variableKey = "dfWarn"
        local variableTbl = settings
        local defaultValue = true
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        -- setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end


    do
        local variable = "twwAnnounce"
        local name = "Khaz Algar - Announce"
        local tooltip = "Make a sound and announce Khaz Algar crates"
        local variableKey = "twwAnnounce"
        local variableTbl = settings
        local defaultValue = true
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        -- setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    
    do
        local variable = "twwTrack"
        local name = "Khaz Algar - Track"
        local tooltip = "Show Khaz Algar crates in /wct output"
        local variableKey = "twwTrack"
        local variableTbl = settings
        local defaultValue = true
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        -- setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    
    do
        local variable = "twwWarn"
        local name = "Khaz Algar - Warn"
        local tooltip = "Make a sound and warn before Khaz Algar crates will drop"
        local variableKey = "twwWarn"
        local variableTbl = settings
        local defaultValue = true
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        -- setting:SetValueChangedCallback(OnSettingChanged)
        Settings.CreateCheckbox(category, setting, tooltip)
    end


    do
        local variable = "muteBounty"
        local name = "Mute Bounty Music"
        local tooltip = "Prevents the bounty music from blasting at you when you gain a bounty"
        local variableKey = "muteBounty"
        local variableTbl = settings
        local defaultValue = false
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(updateMuteBounty)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    
    do
        local variable = "debug"
        local name = "Debugging Mode"
        local tooltip = "Shows addon debugging information"
        local variableKey = "debug"
        local variableTbl = settings
        local defaultValue = false
    
        local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    

    Settings.RegisterAddOnCategory(category)
    NS.settingsCategoryID = category:GetID()
end
NS.configureSettings = configureSettings
