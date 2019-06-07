--[[
    nade.lua
    grenade object
--]]

local obj = require 'obj'
local sprite = require 'sprite'
local map = require 'map'

return {
    init = function(self)
        -- consts
        self.gravity = self.gravity or 350
        self.w = self.w or 16
        self.h = self.h or 16

        -- state
        self.fuse_time = 2.5
        self.shape = love.physics.newCircleShape(self.w / 2)
        self.body = love.physics.newBody(map.get_physics_world(), self.x, self.y, 'dynamic')
        self.fixture = love.physics.newFixture(self.body, self.shape, 1)

        -- resources
        self.spr = sprite.create('16x16_nade.png', self.w, self.h, 0.25)
    end,

    destroy = function(self)
        obj.create(self.__layer, 'explosion', {x = self.x, y = self.y})
    end,

    update = function(self, dt)
        -- decrement fuse and explode if expired
        if self.fuse_time > 0 then
            self.fuse_time = self.fuse_time - dt
        else
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
