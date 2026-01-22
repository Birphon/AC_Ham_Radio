ACHamRadio = ACHamRadio or {}

local AC_TYPES = {
    ACHamRadioPremium = true,
    ACHamRadioMilitary = true,
    ACHamRadioMakeshift = true
}

function ACHamRadio.isACRadio(item)
    return item
        and AC_TYPES[item:getType()]
        and item:getDeviceData()
        and not item:getDeviceData():isBatteryPowered()
end
