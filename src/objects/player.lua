--[[
    player.lua
    basic player object
--]]

local map = require 'map'
local obj = require 'obj'
local sprite = require 'sprite'

return {
    init = function(self)
        -- constants
        self.gravity = self.gravity or 350
        self.crouch_decel = self.crouch_decel or 600
        self.passive_decel = self.passive_decel or 400
        self.jump_dy = self.jump_dy or -180
        self.dx_accel = self.dx_accel or 1600
        self.dx_max = self.dx_max or 150
        self.grenade_dampening = 3

        -- state
        self.dx = 0
        self.dy = 0
        self.jump_enabled = false
        self.is_walking = false
        self.direction = 'right'
        self.nade = nil
        self.throw_enabled = false

        -- resources
        self.idle = sprite.create('32x32_player.png', self.w, self.h, 0.25)
        self.walk = sprite.create('32x32_player-walk.png', self.w, self.h, 0.1)

        self.spr = self.walk
        self.spr:play()

        -- create a camera for the player
        self.camera = obj.create(self.__layer, 'camera', { x = self.x + self.w / 2, y = self.y + self.h / 2 })
    end,
    explode = function(self, _, _)
        -- turn the player into gibs
        obj.create(self.__layer, 'gib', { img = '12x9_player_head.png', x = self.x + 11, y = self.y })
        obj.create(self.__layer, 'gib', { img = '19x13_player_body.png', x = self.x + 8, y = self.y + 8 })
        obj.create(self.__layer, 'gib', { img = '11x10_player_legs.png', x = self.x + 13, y = self.y + 22 })

        obj.destroy(self)
    end,
    update = function(self, dt)
        -- update the sprite
        self.spr:update(dt)

        -- find the world geometry layer if we haven't already
        self.geometry_layer = self.geometry_layer or map.layer_by_name('geometry')

        -- update velocity from inputs
        self.is_walking = false

        -- assume not walking unless we override it
        self.spr = self.idle

        if love.keyboard.isDown('left') then
            self.dx = self.dx - self.dx_accel * dt
            self.is_walking = true
            self.direction = 'left'
            self.spr = self.walk
        end

        if love.keyboard.isDown('right') then
            self.dx = self.dx + self.dx_accel * dt
            self.is_walking = true
            self.direction = 'right'
            self.spr = self.walk
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
            if not self.jump_enabled and not self.is_walking then
                if self.dx > 0 then
                    self.dx = math.max(self.dx - (self.passive_decel / 1.5) * dt, 0)
                else
                    self.dx = math.min(self.dx + (self.passive_decel / 1.5) * dt, 0)
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
        end

        -- throw a grenade if we can/should
        if love.keyboard.isDown('x') and not self.nade and self.throw_enabled then
            -- make a grenade object and keep track of it
            self.nade = obj.create(self.__layer, 'nade', {
                x = self.x + self.w / 2,
                y = self.y + self.h / 2,
            });

            self.throw_enabled = false
        end

        if self.nade then
            self.nade.x = self.x + self.w / 2
            self.nade.y = self.y + self.h / 2
            self.nade.dx = 0
            self.nade.dy = 0

            -- drop the grenade either on release or destruction
            if not love.keyboard.isDown('x') or self.nade.__destroy then
                -- launch the grenade
                self.nade:throw(self.dx / self.grenade_dampening, self.dy / self.grenade_dampening)

                -- release the nade from our control
                self.nade = nil
            end
        end

        if not love.keyboard.isDown('x') then
            self.throw_enabled = true
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
                self.y = collision.y - self.h
                self.jump_enabled = true
            else
                self.y = collision.y + collision.h + 1
            end

            self.dy = 0
        end

        -- update the camera with our location, speed, and direction
        -- also pass if we're on the ground or not
        self.camera:set_focus(self.x,
                              self.x + self.w,
                              self.y,
                              self.y + self.h,
                              self.jump_enabled,
                              self.dx, self.dy, self.direction)
    end,
    render = function(self)
        -- PLACEHOLDER: set color while anim_playing
        if self.anim_playing then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end

        -- clamp player rendering to integers, otherwise fuzzy collisions
        -- end up making the player look all jittery

        self.spr:render(math.floor(self.x), math.floor(self.y), 0, self.direction == 'left')

    end,
}
