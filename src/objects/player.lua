--[[
    player.lua
    basic player object
--]]

local map = require 'map'

return {
    init = function(self)
        self.w = 16
        self.h = 32
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
        if map.collide_aabb(self) then love.graphics.setColor(1, 0, 0, 1) end
        love.graphics.rectangle('line', self.x, self.y, self.w, self.h)
    end,
}
