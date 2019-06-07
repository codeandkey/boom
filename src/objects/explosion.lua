--[[
    explosion.lua
    explosion object
--]]

local obj = require 'obj'

return {
    init = function(self)
        self.anim_time = 1
        self.w = self.w or 32
        self.h = self.h or 32
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
        love.graphics.rectangle('line', self.x - self.w / 2, self.y - self.h / 2, self.w, self.h)
    end,
}
