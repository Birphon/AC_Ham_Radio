ACHamRadio = ACHamRadio or {}

-- Define which radio types are AC-powered
local AC_TYPES = {
    ACHamRadioPremium = true,
    ACHamRadioMilitary = true,
    ACHamRadioMakeshift = true
}

-- Check if an item is an AC Ham Radio
function ACHamRadio.isACRadio(item)
    if not item then return false end
    
    local itemType = item:getType()
    if not AC_TYPES[itemType] then return false end
    
    local data = item:getDeviceData()
    if not data then return false end
    
    -- AC radios should not be battery powered
    return not data:isBatteryPowered()
end

-- Get the base radio type name for display
function ACHamRadio.getRadioTypeName(item)
    if not item then return "Unknown" end
    
    local itemType = item:getType()
    if itemType == "ACHamRadioPremium" then
        return "Premium Technologies"
    elseif itemType == "ACHamRadioMilitary" then
        return "Military Grade"
    elseif itemType == "ACHamRadioMakeshift" then
        return "Makeshift"
    end
    
    return "Unknown"
end

-- Check if an item can be placed as an AC radio (needs to be in world)
function ACHamRadio.canBePlaced(item)
    if not ACHamRadio.isACRadio(item) then return false end
    return true
end

-- Validate radio configuration
function ACHamRadio.validateRadio(item)
    if not item then return false, "No item" end
    if not ACHamRadio.isACRadio(item) then return false, "Not an AC radio" end
    
    local data = item:getDeviceData()
    if not data then return false, "No device data" end
    
    if data:isBatteryPowered() then
        return false, "Should not be battery powered"
    end
    
    return true, "Valid"
end

-- Debug function to print radio info
function ACHamRadio.debugInfo(item)
    if not item then 
        print("ACHamRadio: No item provided")
        return 
    end
    
    print("=== AC Ham Radio Debug Info ===")
    print("Type: " .. tostring(item:getType()))
    print("Is AC Radio: " .. tostring(ACHamRadio.isACRadio(item)))
    
    local data = item:getDeviceData()
    if data then
        print("Has Device Data: true")
        print("Is Battery Powered: " .. tostring(data:isBatteryPowered()))
        print("Is Turned On: " .. tostring(data:getIsTurnedOn()))
        print("Power Level: " .. tostring(data:getPower()))
    else
        print("Has Device Data: false")
    end
    
    local worldItem = item:getWorldItem()
    if worldItem then
        print("Is in World: true")
        local square = worldItem:getSquare()
        if square then
            print("Has Square: true")
            print("Has Electricity: " .. tostring(square:haveElectricity()))
        else
            print("Has Square: false")
        end
    else
        print("Is in World: false (in inventory)")
    end
    print("===============================")
end