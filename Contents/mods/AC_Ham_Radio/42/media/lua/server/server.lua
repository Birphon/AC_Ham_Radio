if not isServer() then return end

-- shared.lua should be auto-loaded by PZ from media/lua/shared/
-- Make sure ACHamRadio table exists
if not ACHamRadio then
    print("ACHamRadio: ERROR - shared.lua not loaded!")
    return
end

-- Recipe callback to convert regular ham radios to AC versions
function ACHamRadio_OnCreate(items, result, player)
    local data = result:getDeviceData()
    if not data then return end

    data:setIsBatteryPowered(false)
    data:setPower(1.0)
    data:setTurnedOn(false)

    result:transmitCompleteItemToClients()
end

-- Power monitoring system
ACHamRadio.PowerMonitor = ACHamRadio.PowerMonitor or {}
local PowerMonitor = ACHamRadio.PowerMonitor

PowerMonitor.radios = {}
PowerMonitor.checkInterval = 10 -- Check every 10 ticks (about 1 second at 10 TPS)
PowerMonitor.tickCounter = 0

-- Register a radio for power monitoring
function PowerMonitor:registerRadio(item)
    if not item or not ACHamRadio.isACRadio(item) then return end
    
    local itemID = item:getID()
    if not self.radios[itemID] then
        self.radios[itemID] = {
            item = item,
            lastPowerState = false
        }
    end
end

-- Unregister a radio from monitoring
function PowerMonitor:unregisterRadio(item)
    if not item then return end
    local itemID = item:getID()
    self.radios[itemID] = nil
end

-- Check if a specific radio has AC power available
function PowerMonitor:hasACPower(item)
    if not item then return false end
    
    local square = item:getWorldItem() and item:getWorldItem():getSquare()
    return square and square:haveElectricity() or false
end

-- Update a single radio's power state
function PowerMonitor:updateRadio(radioData)
    local item = radioData.item
    if not item then return end
    
    local hasPower = self:hasACPower(item)
    local data = item:getDeviceData()
    if not data then return end
    
    -- If power state changed
    if hasPower ~= radioData.lastPowerState then
        if not hasPower and data:getIsTurnedOn() then
            -- Power lost - turn off radio
            data:setTurnedOn(false)
            item:transmitCompleteItemToClients()
        end
        
        radioData.lastPowerState = hasPower
    end
    
    -- If radio is on but no power, force it off
    if data:getIsTurnedOn() and not hasPower then
        data:setTurnedOn(false)
        item:transmitCompleteItemToClients()
    end
end

-- Main update tick
function PowerMonitor:onTick()
    self.tickCounter = self.tickCounter + 1
    
    if self.tickCounter >= self.checkInterval then
        self.tickCounter = 0
        
        -- Clean up invalid radios and update valid ones
        for itemID, radioData in pairs(self.radios) do
            if not radioData.item or not radioData.item:getWorldItem() then
                -- Radio was picked up or destroyed
                self.radios[itemID] = nil
            else
                self:updateRadio(radioData)
            end
        end
    end
end

-- Scan world for AC radios that need monitoring
function PowerMonitor:scanWorld()
    local cellList = getWorld():getCellList()
    for i = 0, cellList:size() - 1 do
        local cell = cellList:get(i)
        for x = 0, cell:getWidth() - 1 do
            for y = 0, cell:getHeight() - 1 do
                local square = cell:getGridSquare(x, y, 0)
                if square then
                    local objects = square:getWorldObjects()
                    for j = 0, objects:size() - 1 do
                        local worldItem = objects:get(j)
                        if worldItem and worldItem:getItem() then
                            local item = worldItem:getItem()
                            if ACHamRadio.isACRadio(item) then
                                self:registerRadio(item)
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Event: When a radio is placed in the world
local function onItemPlaced(item, square, player)
    if ACHamRadio.isACRadio(item) then
        PowerMonitor:registerRadio(item)
        
        -- Initial power check
        local hasPower = PowerMonitor:hasACPower(item)
        local data = item:getDeviceData()
        if data and not hasPower and data:getIsTurnedOn() then
            data:setTurnedOn(false)
            item:transmitCompleteItemToClients()
        end
    end
end

-- Event: When a radio is picked up from the world
local function onItemRemoved(item)
    if ACHamRadio.isACRadio(item) then
        -- Turn off when picked up (no longer has AC power)
        local data = item:getDeviceData()
        if data and data:getIsTurnedOn() then
            data:setTurnedOn(false)
            item:transmitCompleteItemToClients()
        end
        PowerMonitor:unregisterRadio(item)
    end
end

-- Event: Player attempts to turn on/off a radio
local function onRadioInteract(player, device, turnOn)
    if not ACHamRadio.isACRadio(device) then return end
    
    -- If trying to turn on without power, prevent it
    if turnOn and not PowerMonitor:hasACPower(device) then
        if player and not isClient() then
            player:Say("No AC power available")
        end
        return false -- Prevent turning on
    end
end

-- Initialize the system
local function initialize()
    -- Scan for existing radios in the world
    PowerMonitor:scanWorld()
    
    -- Register for game tick updates
    Events.OnTick.Add(function()
        PowerMonitor:onTick()
    end)
    
    -- Note: Project Zomboid doesn't have perfect events for item placement/removal
    -- The OnTick monitoring handles most cases, but you can add these if available:
    -- Events.OnObjectAdded.Add(onItemPlaced)
    -- Events.OnObjectRemoved.Add(onItemRemoved)
end

Events.OnGameStart.Add(initialize)
Events.OnServerStarted.Add(initialize)