--[[
    player.lua
    basic player object
--]]

local map = require 'map'
local obj = require 'obj'

return {
    init = function(self)
        -- constants
        self.gravity = self.gravity or 200
        self.crouch_decel = self.crouch_decel or 600
        self.passive_decel = self.passive_decel or 400
        self.jump_dy = self.jump_dy or -160
        self.dx_accel = self.dx_accel or 1600
        self.dx_max = self.dx_max or 150

        -- state
        self.dx = 0
        self.dy = 0
        self.jump_enabled = false
        self.is_walking = false
    end,
    destroy = function(self)
    end,
    update = function(self, dt)
        -- find the world geometry layer if we haven't already
        self.geometry_layer = self.geometry_layer or map.layer_by_name('geometry')

        -- update velocity from inputs
        self.is_walking = false

        if love.keyboard.isDown('left') then
            self.dx = self.dx - self.dx_accel * dt
            self.is_walking = true
        end

        if love.keyboard.isDown('right') then
            self.dx = self.dx + self.dx_accel * dt
            self.is_walking = true
        end

        -- perform jumping if we can/should
        if love.keyboard.isDown('up') and self.jump_enabled then
            self.dy = self.jump_dy
            self.jump_enabled = false
        end

        -- slow the player down when 'down' is pressed
        if love.keyboard.isDown('down') then
            if self.dx > 0 then
                self.dx = math.max(self.dx - self.crouch_decel * dt, 0)
            else
                self.dx = math.min(self.dx + self.crouch_decel * dt, 0)
            end
        else
            if self.jump_enabled and not self.is_walking then
                if self.dx > 0 then
                    self.dx = math.max(self.dx - self.passive_decel * dt, 0)
                else
                    self.dx = math.min(self.dx + self.passive_decel * dt, 0)
                end
            end
        end

        -- limit maximum horizontal speed
        if self.dx > self.dx_max then
            self.dx = self.dx_max
        elseif self.dx < -self.dx_max then
            self.dx = -self.dx_max
        end

        -- apply gravity
        self.dy = self.dy + self.gravity * dt

        -- if the player is moving suspiciously vertically then disable jumping
        if math.abs(self.dy) > 20 then
            self.jump_enabled = false
        end

        -- resolve new velocity
        -- first, resolve horizontal movement

        self.x = self.x + self.dx * dt
        local collision = obj.get_collisions(self, self.geometry_layer, true)

        if collision ~= nil then
            -- resolve a horizontal collision, depending on direction of movement
            if self.dx > 0 then
                self.x = collision.x - (self.w + 1)
            elseif self.dx < 0 then
                self.x = collision.x + collision.w + 1
            else
                assert(false) -- if this ever happens then there are problems
            end

            self.dx = 0
        end

        -- now, resolve vertical movement
        
        self.y = self.y + self.dy * dt
        collision = obj.get_collisions(self, self.geometry_layer, true)

        if collision ~= nil then
            if self.dy >= 0 then
                -- here it's safer to assume dy==0 -> the player was moving somewhat down-ish
                self.y = collision.y - (self.h + 1)
                self.jump_enabled = true
            else
                self.y = collsiion.y + collision.h + 1
            end

            self.dy = 0
        end
    end,
    render = function(self)
        love.graphics.setColor(1, 0, 1, 1)

        -- clamp player rendering to integers, otherwise fuzzy collisions
        -- end up making the player look all jittery
        love.graphics.rectangle('line', math.floor(self.x), math.floor(self.y), self.w, self.h)
    end,
}
