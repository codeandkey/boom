--[[
    player.lua
    basic player object
--]]

local player_width = 16
local player_height = 32

return {
    init = function(self)
    end,
    destroy = function(self)
    end,
    update = function(self, dt)
        if love.keyboard.isDown('left') then
            self.x = self.x - 300 * dt
        end

        if love.keyboard.isDown('right') then
            self.x = self.x + 300 * dt
        end

        if love.keyboard.isDown('up') then
            self.y = self.y - 300 * dt
        end

        if love.keyboard.isDown('down') then
            self.y = self.y + 300 * dt
        end
    end,
    render = function(self)
        love.graphics.setColor(1, 0, 1, 1)
        love.graphics.rectangle('line', self.x, self.y, player_width, player_height)
    end,
}
