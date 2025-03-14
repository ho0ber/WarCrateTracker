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

    do
        local name = "Staleness Threshold"
        local variable = "staleness"
        local defaultValue = 20
        local minValue = 1
        local maxValue = 120
        local step = 1


    	local function GetValue()
            return settings.staleness or defaultValue
        end
    
        local function SetValue(value)
            settings.staleness = value
        end
    
        local setting = Settings.RegisterProxySetting(category, variable, type(defaultValue), name, defaultValue, GetValue, SetValue)
        -- setting:SetValueChangedCallback(OnSettingChanged)
    
        local tooltip = "Stops warning and displaying crates that haven't been seen in this many rotations"
        local options = Settings.CreateSliderOptions(minValue, maxValue, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
        Settings.CreateSlider(category, setting, options, tooltip)
    end

    do
        local name = "ZoneMap Scale"
        local variable = "zoneMapScale"
        local defaultValue = 100
        local minValue = 1
        local maxValue = 200
        local step = 1


    	local function GetValue()
            return settings.zoneMapScale or defaultValue
        end
    
        local function SetValue(value)
            settings.zoneMapScale = value
        end

        local function ZoneMapSettingChanged()
            if BattlefieldMapFrame ~= nil then
                BattlefieldMapFrame:SetScale(settings.zoneMapScale/100)
            end
        end
    
        local setting = Settings.RegisterProxySetting(category, variable, type(defaultValue), name, defaultValue, GetValue, SetValue)
        setting:SetValueChangedCallback(ZoneMapSettingChanged)
    
        local tooltip = "Sets the scale of the ZoneMap you can open with Shift+M"
        local options = Settings.CreateSliderOptions(minValue, maxValue, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
        Settings.CreateSlider(category, setting, options, tooltip)
    end

    Settings.RegisterAddOnCategory(category)
    NS.settingsCategoryID = category:GetID()

    --defaults on this doesn't seem to work right otherwise
    if settings.staleness == nil then
        settings.staleness = 20
    end
end
NS.configureSettings = configureSettings
