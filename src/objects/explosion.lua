--[[
    explosion.lua
    explosion object
--]]

local obj = require 'obj'
local map = require 'map'

return {
    init = function(self)
        self.anim_time = 1
        self.w = self.w or 32
        self.h = self.h or 32
        self.intensity = self.intensity or 10000

        -- apply an impulse to nearby physics objects
        local phys_objects = map.layer_by_name('phys_objects')

        for _, box in pairs(phys_objects) do
            local impulse_normal = {
                x = box.body:getX() - (self.x + self.w / 2),
                y = box.body:getY() - (self.y + self.h / 2),
            }

            -- normalize the impulse vector to length 1
            local length = math.sqrt(math.pow(impulse_normal.x, 2) + math.pow(impulse_normal.y, 2))

            impulse_normal.x = impulse_normal.x / math.pow(length, 2)
            impulse_normal.y = impulse_normal.y / math.pow(length, 2)

            -- re-multiply by the explosion intensity
            impulse_normal.x = impulse_normal.x * self.intensity
            impulse_normal.y = impulse_normal.y * self.intensity

            box.body:applyLinearImpulse(impulse_normal.x, impulse_normal.y)
        end
    end,

    update = function(self, dt)
        if self.anim_time > 0 then
            self.anim_time = self.anim_time - dt
        else
            obj.destroy(self)
        end
    end,

    render = function(self)
        love.graphics.setColor(1, 0, 1, 1)
        love.graphics.rectangle('line', self.x - self.w / 2, self.y - self.h / 2, self.w, self.h)
    end,
}
