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
        self.angle = self.angle or 0
        self.spin = self.spin or math.random(-100, 100)
        self.in_flash = false

        -- flash phases. Sets the color and timing for flashes.
        self.flash_params = {
            { color={ 1, 0.2, 0, 1 }, pct=0.0, delay=0.07 },  -- red
            { color={ 1, 0.7, 0, 1 }, pct=0.25, delay=0.15 }, -- yellow
            { color={ 1, 1, 1, 1 }, pct=0.5, delay=0.3 },   -- white
        }

        -- state
        self.fuse_time = self.fuse_time or 2.5
        self.init_fuse_time = self.init_fuse_time or self.fuse_time -- initial fuse time, needed for flashing
        self.flash_timer = 0
        self.flash_color = { 0.3, 0.3, 0.3, 1 }
        self.thrown = false

        -- resources
        self.spr = sprite.create('16x16_nade.png', self.w, self.h, 0.25)

        -- function to throw/launch the grenade
        self.throw = function(this, dx, dy)
            -- don't create the phys object until thrown
            this.shape = love.physics.newCircleShape(this.w / 2)
            this.body = love.physics.newBody(map.get_physics_world(), this.x, this.y, 'dynamic')
            this.fixture = love.physics.newFixture(this.body, this.shape, 1)
            this.body:applyLinearImpulse(dx, dy)
            this.body:applyAngularImpulse(this.spin)
            this.thrown = true
        end
    end,

    destroy = function(self)
        obj.create(self.__layer, 'explosion', {x = self.body:getX(), y = self.body:getY()})
        self.body:destroy()
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

        -- update from physics object only after thrown
        if self.thrown then
            self.x, self.y = self.body:getPosition()
            self.angle = self.body:getAngle()
        end

        love.graphics.draw(self.spr.image, self.spr:frame(),
                           self.x, self.y,
                           self.angle,
                           1, 1, self.w / 2, self.h / 2)

        love.graphics.setShader()
    end,
}
