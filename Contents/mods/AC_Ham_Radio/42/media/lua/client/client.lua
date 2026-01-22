require "shared/shared"
require "Radio/ISRadioDevicePanel"

-- Store original functions
local originalRender = ISRadioDevicePanel.render
local originalOnPowerButton = ISRadioDevicePanel.onPowerButton

-- Enhanced render with AC power status display
function ISRadioDevicePanel:render()
    originalRender(self)

    local item = self.device
    if not ACHamRadio.isACRadio(item) then return end

    local square = item:getWorldItem() and item:getWorldItem():getSquare()
    local hasPower = square and square:haveElectricity()
    local data = item:getDeviceData()
    local isOn = data and data:getIsTurnedOn()

    local text, outline, bg

    if hasPower then
        if isOn then
            text = "AC Powered (ON)"
            outline = {0.2, 0.8, 0.2, 1}
            bg = {0.6, 1.0, 0.6, 0.35}
        else
            text = "AC Powered (OFF)"
            outline = {0.4, 0.8, 0.4, 1}
            bg = {0.7, 1.0, 0.7, 0.25}
        end
    else
        text = "No AC Power"
        outline = {0.8, 0.2, 0.2, 1}
        bg = {1.0, 0.6, 0.6, 0.35}
    end

    local x = self.x + 10
    local y = self.y + self.height - 38
    local w = self.width - 20
    local h = 26

    self:drawRect(x, y, w, h, bg[4], bg[1], bg[2], bg[3])
    self:drawRectBorder(x, y, w, h, 1, outline[1], outline[2], outline[3])
    self:drawTextCentre(text, x + w / 2, y + 6, 1, 1, 1, 1, UIFont.Small)
end

-- Override power button to check for AC power before allowing turn-on
function ISRadioDevicePanel:onPowerButton()
    local item = self.device
    
    -- Check if this is an AC radio trying to turn on without power
    if ACHamRadio.isACRadio(item) then
        local data = item:getDeviceData()
        local isCurrentlyOn = data and data:getIsTurnedOn()
        
        -- If trying to turn ON (currently off)
        if not isCurrentlyOn then
            local square = item:getWorldItem() and item:getWorldItem():getSquare()
            local hasPower = square and square:haveElectricity()
            
            if not hasPower then
                -- Show message to player
                local player = getSpecificPlayer(self.playerNum)
                if player then
                    player:Say("This radio requires AC power from a generator")
                end
                
                -- Play error sound (optional)
                getSoundManager():PlayUISound("UIClickDenied")
                
                return -- Don't call original function
            end
        end
    end
    
    -- Call original function for normal behavior
    originalOnPowerButton(self)
end

-- Client-side helper to check power status
ACHamRadio.checkPowerStatus = function(item)
    if not ACHamRadio.isACRadio(item) then return true end
    
    local square = item:getWorldItem() and item:getWorldItem():getSquare()
    return square and square:haveElectricity() or false
end

-- Update radio display when placed/picked up
local function onPlayerUpdate()
    -- This ensures the UI updates when power state changes
    local playerNum = 0
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    
    -- Check if radio panel is open
    local ui = ISRadioDevicePanel.instance
    if ui and ui:isVisible() and ui.device then
        if ACHamRadio.isACRadio(ui.device) then
            local data = ui.device:getDeviceData()
            if data and data:getIsTurnedOn() then
                -- Check if power was lost
                if not ACHamRadio.checkPowerStatus(ui.device) then
                    -- Power lost - the server will turn it off, UI will update
                    ui:setVisible(false)
                    ui:setVisible(true)
                end
            end
        end
    end
end

-- Register periodic update check (every ~2 seconds)
local updateCounter = 0
local updateInterval = 200 -- ticks

Events.OnTick.Add(function()
    updateCounter = updateCounter + 1
    if updateCounter >= updateInterval then
        updateCounter = 0
        onPlayerUpdate()
    end
end)