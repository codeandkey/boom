--[[
    camera.lua
    camera object

    the camera object has some useful member functions to help with effects:

    local cam = obj.create(..., 'camera')

    cam:center_on(x, y) -- set camera target center to (<x>, <y>)
    cam:resize(size)    -- set camera target size to <size>
--]]

local camera = require 'camera'

return {
    init = function(self)
        -- constants
        self.target_size = self.target_size or 600 -- default target size

        -- animation factors
        -- higher is slower
        self.size_anim_factor = self.size_anim_factor or 1
        self.position_anim_factor = self.position_anim_factor or 2

        -- state
        self.size = self.target_size
        self.last_size = self.size
        self.target_x = self.x
        self.target_y = self.y

        -- member functions
        self.center_on = function(self, x, y)
            self.target_x = x
            self.target_y = y
        end

        self.resize = function(self, size)
            if size ~= nil then
                self.last_size = self.size
                self.size = size
            else
                self.target_size = self.last_size
            end
        end
    end,

    update = function(self, dt)
        -- update camera size and position from dt
        self.size = self.size + dt * self.size_anim_factor * (self.target_size - self.size)
        self.x = self.x + dt * self.position_anim_factor * (self.target_x - self.x)
        self.y = self.y + dt * self.position_anim_factor * (self.target_y - self.y)

        -- update engine camera with new values
        camera.set(self.x, self.y, self.size)
    end,
}
