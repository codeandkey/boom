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
        self.intensity = self.intensity or 300
        self.radius = self.radius or 75
        self.resolution = self.resolution or 100

        -- shoot out explosion rays
        for i=0,self.resolution-1 do
            local theta = (i / self.resolution) * 3.141 * 2.0

            -- pew pew
            map.get_physics_world():rayCast(
                self.x, self.y,
                self.x + self.radius * math.cos(theta),
                self.y + self.radius * math.sin(theta),
                function (fixture, x, y, xn, yn, fraction)
                    -- compute the impulse vector
                    local impulse_vector = {
                        x = x - self.x,
                        y = y - self.y,
                    }

                    local impulse_length = fraction * self.radius

                    -- normalize to appropriate intensity
                    impulse_vector.x = impulse_vector.x * self.intensity / math.pow(impulse_length, 2)
                    impulse_vector.y = impulse_vector.y * self.intensity / math.pow(impulse_length, 2)

                    -- grab the body and throw it
                    fixture:getBody():applyLinearImpulse(impulse_vector.x, impulse_vector.y, x, y)

                    return 0
                end
            )
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
