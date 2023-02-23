function (modTable)
    if TRP3_NAMEPLATES_ADDON ~= nil and TRP3_NAMEPLATES_ADDON ~= "Plater" then
        return false
    end
    
    function modTable:Init()
        if not IsAddOnLoaded("TotalRP3") then
            return false
        end
        
        if not _G.TRP3_API then return end
        
        modTable.TRP3_API = _G.TRP3_API
        modTable.TRP3Nameplates = _G.TRP3_NamePlates
        modTable.TRP3_NamePlatesUtil = _G.TRP3_NamePlatesUtil
        modTable.L = modTable.TRP3_API.loc
        
        TRP3_NAMEPLATES_ADDON = "Plater"
        
        modTable.unitDisplayInfo = {}
        modTable.initialized = {}
        
        modTable.guildNameColor = modTable.TRP3_API.utils.color.colorCodeFloat(unpack(modTable.config.guildNameColor))
        modTable.guildMemberColor = modTable.TRP3_API.utils.color.colorCodeFloat(unpack(modTable.config.guildMemberColor))
        
        modTable.fullTitleColor = modTable.TRP3_API.utils.color.colorCodeFloat(unpack(modTable.config.fullTitleColor))
        modTable.useFullTitleColor = modTable.config.useFullTitleColor
        
        modTable.ready = true
        
        modTable.TRP3_API.Events.registerCallback("CONFIGURATION_CHANGED", function(...) return modTable:OnConfigurationChanged(...); end);
        
        modTable.TRP3_API.Events.registerCallback("REGISTER_DATA_UPDATED", function(...) return modTable:OnRegisterDataUpdated(...); end);
        
        modTable:UpdateAllNameplates()
        return true
    end
    
    function modTable:GetUnitDisplayInfo(unitToken)
        return modTable.unitDisplayInfo[unitToken]
    end
    
    function modTable:SetUnitDisplayInfo(unitToken, displayInfo)
        modTable.unitDisplayInfo[unitToken] = displayInfo
    end
    
    function modTable:GetNormalizedUnitName(unitToken)
        local unitName, unitRealm = UnitName(unitToken)
        
        if not unitRealm or unitRealm == "" then
            unitRealm = GetNormalizedRealmName()
        end
        
        return unitName .. "-" .. unitRealm
    end
    
    function modTable:UpdateNameplate(unitFrame)
        if not unitFrame or unitFrame.actorType ~= "friendlyplayer" or not unitFrame.PlaterOnScreen then
            return
        end
        
        if not modTable.ready then
            local init = modTable:Init()
            if init ~= true then
                return
            end
        end
        
        local plateFrame = unitFrame.PlateFrame
        local unitToken = plateFrame.namePlateUnitToken
        local displayInfo = modTable.TRP3Nameplates:GetUnitDisplayInfo(unitToken)
        
        local RPDisplayName = nil
        
        modTable.initialized[modTable:GetNormalizedUnitName(unitToken)] = unitToken
        
        if not displayInfo then return end
        
        modTable:SetUnitDisplayInfo(unitToken, displayInfo)
        
        --Set the name to the unit's RP name
        if displayInfo.name then
            if GetUnitName(unitToken, false) == "Hypersonic" then
                RPDisplayName = modTable.TRP3_API.utils.Oldgodify(displayInfo.name)
            else
                RPDisplayName = modTable.TRP3_API.utils.str.crop(displayInfo.name, modTable.TRP3_NamePlatesUtil.MAX_NAME_CHARS)
            end
        else
            RPDisplayName = GetUnitName(unitToken, false)
        end
        
        if not RPDisplayName then return end
        
        --Insert the RP status if necessary
        if displayInfo.roleplayStatus then
            local preferredStyle = modTable.TRP3_NamePlatesUtil:GetPreferredOOCIndicatorStyle()
            if displayInfo.roleplayStatus == AddOn_TotalRP3.Enums.ROLEPLAY_STATUS.OUT_OF_CHARACTER then
                if preferredStyle == "ICON" then
                    RPDisplayName = modTable.TRP3_NamePlatesUtil.OOC_ICON .. RPDisplayName
                else
                    RPDisplayName = "|cffff0000" .. "[" .. modTable.L.CM_OOC .. "]|r " .. RPDisplayName
                end
            end
        end
        
        --Insert the full RP title
        if displayInfo.fullTitle and not displayInfo.shouldHide then
            local fullTitle = modTable.TRP3_API.utils.str.crop(displayInfo.fullTitle, modTable.TRP3_NamePlatesUtil.MAX_TITLE_CHARS)
            if modTable.useFullTitleColor then
                RPDisplayName = RPDisplayName .. "\n" .. modTable.fullTitleColor .. fullTitle .. "|r"
            else
                RPDisplayName = RPDisplayName .. "\n"  .. fullTitle
            end
        end
        
        --Append guild name
        if plateFrame.PlateConfig.show_guild_name then
            if plateFrame.playerGuildName and not RPDisplayName:find("<" .. plateFrame.playerGuildName .. ">") then
                if plateFrame.playerGuildName == Plater.PlayerGuildName then
                    RPDisplayName = RPDisplayName .. "\n" .. modTable.guildMemberColor .. "<" .. plateFrame.playerGuildName .. ">|r"
                else
                    RPDisplayName = RPDisplayName .. "\n" .. modTable.guildNameColor .. "<" .. plateFrame.playerGuildName .. ">|r"
                end
            end
        end
        
        --Add the icon widget if it doesn't exist, if it does, update it
        if displayInfo.icon and not plateFrame.TRP3Icon and not displayInfo.shouldHide then
            do
                local iconWidget = plateFrame:CreateTexture(nil, "ARTWORK")
                iconWidget:ClearAllPoints()
                iconWidget:SetPoint("RIGHT", plateFrame.CurrentUnitNameString, "LEFT", -4, 0) -- may need to reparent based on healthbar?
                iconWidget:Hide()
                
                plateFrame.TRP3Icon = iconWidget
            end
        elseif displayInfo.icon and plateFrame.TRP3Icon and not displayInfo.shouldHide then
            plateFrame.TRP3Icon:ClearAllPoints()
            plateFrame.TRP3Icon:SetTexture(modTable.TRP3_API.utils.getIconTexture(displayInfo.icon))
            plateFrame.TRP3Icon:SetSize(modTable.TRP3_NamePlatesUtil.GetPreferredIconSize())
            plateFrame.TRP3Icon:SetPoint("RIGHT", plateFrame.CurrentUnitNameString, "LEFT", -4, 0)
            plateFrame.TRP3Icon:Show()
        elseif plateFrame.TRP3Icon then
            plateFrame.TRP3Icon:Hide()
        end
        
        --Update nameplate visibility
        if displayInfo.shouldHide then
            unitFrame:Hide()
        else
            unitFrame:Show()
        end
        
        --Set the color of the name to the RP profile color
        if displayInfo.shouldColorName then
            RPDisplayName = displayInfo.color:WrapTextInColorCode(RPDisplayName)
        end
        
        --Set the nameplate color to color the health bar
        if displayInfo.shouldColorHealth then
            Plater.SetNameplateColor(unitFrame, displayInfo.color:GetRGBTable())
        end
        
        plateFrame.CurrentUnitNameString:SetText(RPDisplayName)
        unitFrame.namePlateUnitName = RPDisplayName
        plateFrame.namePlateUnitName = RPDisplayName
    end
    
    function modTable:UpdateAllNameplates()
        for _, nameplate in ipairs(C_NamePlate:GetNamePlates()) do
            local unitFrame = nameplate.unitFrame
            if not unitFrame then return end
            modTable:UpdateNameplate(unitFrame)
        end
    end
    
    function modTable:OnRegisterDataUpdated(unitName, ...)
        if not unitName then return end
        
        if modTable.initialized[unitName] then
            local nameplate = C_NamePlate.GetNamePlateForUnit(modTable.initialized[unitName])
            if nameplate and unitName == modTable:GetNormalizedUnitName(nameplate.namePlateUnitToken)  then
                modTable:UpdateNameplate(nameplate.unitFrame)
            end
        end
    end
    
    function modTable:OnConfigurationChanged(...)
        modTable:UpdateAllNameplates()
    end
end