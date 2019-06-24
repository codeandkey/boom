--[[
    explosion.lua
    explosion object
--]]

local camera = require 'camera'
local obj = require 'obj'
local map = require 'map'

return {
    init = function(self)
        self.anim_time = 1
        self.w = self.w or 32
        self.h = self.h or 32
        self.intensity = self.intensity or 20
        self.radius = self.radius or 300
        self.resolution = self.resolution or 100
        self.object_range = self.object_range or 100

        -- shake the camera a bit
        camera.setshake(3)

        --[[
            look for nearby objects to splode and tell them
            it's important this is done before the explosion rays go out into the 
            physics world -- now we can create the gib objects inside the explosion handler,
            and the gibs will be pushed by the rays instead of requiring an explosion vector
        --]]
        map.foreach_object(function(other_obj)
            local dist = math.sqrt(math.pow(other_obj.x - self.x, 2) + math.pow(other_obj.y - self.y, 2))

            if dist < self.object_range then
                -- notify the object: it just got sploded
                if other_obj.__type.explode ~= nil then
                    -- pass the vector anyway for giggles
                    other_obj.__type.explode(other_obj, (other_obj.x - self.x) / dist, (other_obj.y - self.y) / dist)
                end
            end
        end)

        -- shoot out explosion rays
        for i=0,self.resolution-1 do
            local theta = (i / self.resolution) * 3.141 * 2.0

            -- pew pew
            map.get_physics_world():rayCast(
                self.x, self.y,
                self.x + self.radius * math.cos(theta),
                self.y + self.radius * math.sin(theta),
                function (fixture, x, y, _, _, fraction)
                    -- compute the impulse vector
                    local impulse_vector = {
                        x = x - self.x,
                        y = y - self.y,
                    }

                    local impulse_length = fraction * self.radius

                    -- normalize to appropriate intensity
                    impulse_vector.x = impulse_vector.x * self.intensity / math.pow(impulse_length, 1)
                    impulse_vector.y = impulse_vector.y * self.intensity / math.pow(impulse_length, 1)

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
