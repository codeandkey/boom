--[[
    explosion.lua
    explosion object
--]]

local obj = require 'obj'
local width = 32
local height = 32

return {
    init = function(self)
        self.anim_time = 1
    end,

    update = function(self, dt)
        if self.anim_time > 0 then
            self.anim_time = self.anim_time - dt
        else
            self.anim_time = 0
            obj.destroy(self)
        end
    end,

    render = function(self)
        love.graphics.setColor(1, 0, 1, 1)
        love.graphics.rectangle('line', self.x, self.y, width, height)
    end,
}
