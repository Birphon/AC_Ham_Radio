if isClient() then return end

require "shared/shared"

function ACHamRadio_OnCreate(items, result, player)
    local data = result:getDeviceData()
    if not data then return end

    data:setIsBatteryPowered(false)
    data:setPower(1.0)
    data:setTurnedOn(false)

    result:transmitCompleteItemToClients()
end
