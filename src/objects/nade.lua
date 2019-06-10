--[[
    nade.lua
    grenade object
--]]

local obj = require 'obj'
local shaders = require 'shaders'
local sprite = require 'sprite'
local map = require 'map'

return {
    init = function(self)
        -- consts
        self.gravity = self.gravity or 350
        self.w = self.w or 16
        self.h = self.h or 16
        self.spin = self.spin or math.random(-100, 100)
        self.in_flash = false

        -- flash phases. Sets the color and timing for flashes.
        self.flash_params = {
            { color={ 1, 0.2, 0, 1 }, pct=0.0, delay=0.07 },  -- red
            { color={ 1, 0.7, 0, 1 }, pct=0.25, delay=0.15 }, -- yellow
            { color={ 1, 1, 1, 1 }, pct=0.5, delay=0.3 },   -- white
        }

        -- state
        self.fuse_time = 2.5
        self.init_fuse_time = self.fuse_time -- initial fuse time, needed for flashing
        self.flash_timer = 0
        self.flash_color = { 0.3, 0.3, 0.3, 1 }
        self.shape = love.physics.newCircleShape(self.w / 2)
        self.body = love.physics.newBody(map.get_physics_world(), self.x, self.y, 'dynamic')
        self.fixture = love.physics.newFixture(self.body, self.shape, 1)

        -- resources
        self.spr = sprite.create('16x16_nade.png', self.w, self.h, 0.25)

        -- apply initial force
        self.body:applyLinearImpulse(self.dx, self.dy)
        self.body:applyAngularImpulse(self.spin)
    end,

    destroy = function(self)
        obj.create(self.__layer, 'explosion', {x = self.body:getX(), y = self.body:getY()})
    end,

    update = function(self, dt)
        -- decrement fuse and explode if expired
        if self.fuse_time > 0 then
            self.fuse_time = self.fuse_time - dt
        else
            obj.destroy(self)
        end
        
        self.flash_timer = self.flash_timer - dt

        -- set flash phase based on current fuse time
        if self.flash_timer < 0 then
            self.in_flash = not self.in_flash
            local pct = self.fuse_time / self.init_fuse_time

            for _, phase in ipairs(self.flash_params) do
                if pct > phase.pct then
                    self.flash_timer = phase.delay
                    self.flash_color = phase.color
                end
            end
        end
    end,

    render = function(self)
        if self.in_flash then
            love.graphics.setColor(self.flash_color)
            love.graphics.setShader(shaders.flash)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end

        love.graphics.draw(self.spr.image, self.spr:frame(),
                           self.body:getX(), self.body:getY(),
                           self.body:getAngle(),
                           1, 1, self.w / 2, self.h / 2)

        love.graphics.setShader()
    end,
}
