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
        self.size_anim_factor = self.size_anim_factor or 2
        self.position_anim_factor = self.position_anim_factor or 2

        -- state
        self.size = self.target_size
        self.last_size = self.size
        self.target_x = self.x
        self.target_y = self.y

        -- member functions
        self.center_on = function(this, x, y)
            this.target_x = x
            this.target_y = y
        end

        -- NOTE: Seems to cause camera to teleport if set during loop
        self.resize = function(this, size)
            if size ~= nil then
                this.last_size = this.size
                this.size = size
            else
                this.target_size = this.last_size
            end
        end

        -- useful for letting camera resolve itself while still controlling location
        self.settargetsize = function(this, target)
            this.target_size = target
        end

    end,

    update = function(self, dt)
        -- update camera size and position from dt
        self.size = self.size + dt * self.size_anim_factor * (self.target_size - self.size)
        self.dx = self.position_anim_factor * (self.target_x - self.x)
        self.dy = self.position_anim_factor * (self.target_y - self.y)

        self.x = self.x + self.dx * dt
        self.y = self.y + self.dy * dt

        -- update engine camera with new values
        camera.set(self.x, self.y, self.size)
    end,
}
