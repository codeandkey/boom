--[[
    gib.lua
    gib object
--]]

local obj = require 'obj'
local map = require 'map'
local sprite = require 'sprite'

return {
    init = function(self)
        self.flash_timer      = 0
        self.flash_timer_base = 0.1
        self.flash_threshold  = 0.4
        self.clean_timer      = 5 + math.random(1, 4)
        self.angle            = 0
        self.in_flash         = false

        self.spr = sprite.create(self.img, nil, nil, 0)
        self.color = self.color or {1, 1, 1, 1}

        self.w = self.spr.frame_w
        self.h = self.spr.frame_h

        -- make a physics body that covers the sprite
        self.shape = love.physics.newRectangleShape(self.w, self.h)
        self.body = love.physics.newBody(map.get_physics_world(), self.x + self.w / 2, self.y + self.h / 2, 'dynamic')
        self.fixture = love.physics.newFixture(self.body, self.shape)
    end,

    destroy = function(self)
        self.body:destroy()
    end,

    update = function(self, dt)
        self.clean_timer = self.clean_timer - dt

        if self.clean_timer < self.flash_threshold then
            self.flash_timer = self.flash_timer - dt

            if self.flash_timer <= 0 then
                self.flash_timer = self.flash_timer_base
                self.in_flash = not self.in_flash
            end
        end

        if self.clean_timer < 0 then
            obj.destroy(self)
        end

        self.x, self.y = self.body:getPosition()
        self.angle = self.body:getAngle()
    end,

    render = function(self)
        if not self.in_flash then
            love.graphics.setColor(self.color)

            love.graphics.draw(self.spr.image, self.spr:frame(),
                               self.x, self.y, self.angle, 1, 1,
                               self.w / 2, self.h / 2)
        end
    end,
}
