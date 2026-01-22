require "shared/shared"
require "Radio/ISRadioDevicePanel"

local originalRender = ISRadioDevicePanel.render

function ISRadioDevicePanel:render()
    originalRender(self)

    local item = self.device
    if not ACHamRadio.isACRadio(item) then return end

    local square = item:getWorldItem() and item:getWorldItem():getSquare()
    local hasPower = square and square:haveElectricity()

    local text, outline, bg

    if hasPower then
        text = "AC Powered"
        outline = {0.2, 0.8, 0.2, 1}
        bg = {0.6, 1.0, 0.6, 0.35}
    else
        text = "AC Disconnected"
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
