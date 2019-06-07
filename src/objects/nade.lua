--[[
    nade.lua
    grenade object
--]]

local obj = require 'obj'
local sprite = require 'sprite'

return {
    init = function(self)
        -- consts
        self.gravity = self.gravity or 350
        self.w = self.w or 16
        self.h = self.h or 16

        -- state
        self.fuse_time = 100

        -- resources
        self.spr = sprite.create('16x16_nade.png', self.w, self.h, 0.25)
    end,

    destroy = function(self)
	    obj.create(self.__layer, 'explosion', {x = self.x, y = self.y})
    end,

    update = function(self, dt)
        -- decrement fuse and explode if expired
        if self.fuse_time > 0 then
            self.fuse_time = self.fuse_time - 1
        else
            self.fuse_time = 0
            obj.destroy(self)
        end

	    -- apply gravity
	    self.dy = self.dy + self.gravity * dt

	    -- update position
	    self.x = self.x + self.dx * dt
	    self.y = self.y + self.dy * dt
    end,

    render = function(self)
	    love.graphics.draw(self.spr.image, self.spr:frame(), self.x, self.y)
    end,
}
