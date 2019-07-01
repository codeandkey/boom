--[[
    enemy_bomber.lua
    basic bomber enemy

    the bomber enemy behaves like a player.
    if the player comes too close, the bomber will move towards the player and explode.
--]]

local map = require 'map'
local obj = require 'obj'
local sprite = require 'sprite'

return {
    init = function(self)
        -- constants
        self.gravity = self.gravity or 350
        self.passive_decel = self.passive_decel or 400
        self.jump_dy = self.jump_dy or -180
        self.dx_accel = self.dx_accel or 1600
        self.dx_max = self.dx_max or 150
        self.moveintent = 2
        self.jumpintent = 2
        self.nextmovetimer = 0
        self.movetimer = 1
        self.jumptimer = 1
        self.Name = self.name or ''

        self.aggro_distance = 400
        self.explode_distance = 40

        -- state
        self.dx = 0
        self.dy = 0
        self.jump_enabled = false
        self.is_walking = false
        self.walked_into_wall = false -- true iff we walked into a wall in the last update
        self.direction = 'right'

        -- color
        self.color = { self.r or 1, self.g or 1, self.b or 1, self.a or 1 }

        -- resources
        self.idle = sprite.create('32x32_player.png', self.w, self.h, 0.25)
        self.walk = sprite.create('32x32_player-walk.png', self.w, self.h, 0.1)
        self.jump = sprite.create('32x32_player-jump.png', self.w, self.h, 0.05)

        self.spr = self.jump
        self.spr:play()

        self.spr = self.walk
        self.spr:play()
    end,

    explode = function(self, _, _)
        -- explode into colorful gibs
        obj.create(self.__layer, 'gib', {
            img = '12x9_player_head.png',
            x = self.x + 11, y = self.y,
            color = self.color
        })

        obj.create(self.__layer, 'gib', {
            img = '19x13_player_body.png',
            x = self.x + 8, y = self.y + 8,
            color = self.color
        })

        obj.create(self.__layer, 'gib', {
            img = '11x10_player_legs.png',
            x = self.x + 13, y = self.y + 22,
            color = self.color
        })

        obj.destroy(self)
    end,

    update = function(self, dt)
        -- update the sprite
        self.spr:update(dt)

        -- find the world geometry layer if we haven't already
        self.geometry_layer = self.geometry_layer or map.layer_by_name('geometry')

        -- find the player object
        self.player_obj = self.player_obj or map.object_by_name('player')

        -- update velocity from inputs
        self.is_walking = false

        -- assume not walking unless we override it
        self.spr = self.idle

        -- wait a little bit before deciding what to do next
        if self.nextmovetimer > 0 then
            self.nextmovetimer = self.nextmovetimer - dt
        else
            self.moveintent = math.random(0, 2)
            self.nextmovetimer = 2
            self.movetimer = 1
        end

        if self.jumptimer > 0 then
            self.jumptimer = self.jumptimer - dt
        else
            self.jumpintent = math.random(0, 3)
            self.jumptimer = 1
        end

        if self.movetimer > 0 then
            self.movetimer = self.movetimer - dt
        else
            self.keepmoving = math.random(0, 1)

            if self.keepmoving == 0 then
                self.moveintent = 2
           end

           self.movetimer = 1
        end

        --ensure timers always hit 0 and reset
        if self.movetimer < 0 then
            self.movetimer = 0
        end

        if self.jumptimer < 0 then
            self.jumptimer = 0
        end

        local wants_left, wants_right, wants_jump = false, false, false

        -- compute enemy pseudoinputs
        local dist_to_player = nil

        if self.player_obj then
            dist_to_player = math.sqrt(math.pow(self.x - self.player_obj.x, 2) +
                                       math.pow(self.y - self.player_obj.y, 2))
        end

        if dist_to_player and dist_to_player < self.aggro_distance then
            -- enemy has aggro, move towards the player
            if self.x > self.player_obj.x then
                wants_left = true
            elseif self.x < self.player_obj.x then
                wants_right = true
            end

            -- jump if we've hit an obstacle
            if (wants_left or wants_right) and self.walked_into_wall then
                wants_jump = true
            end

            -- if we're close enough, explode
            if dist_to_player < self.explode_distance then
                obj.create(self.__layer, 'explosion', {
                    x = self.x + self.w / 2, y = self.y + self.h / 2
                })
            end
        else
            -- player is not found or not close enough, wander randomly
            if self.moveintent == 0 then
                wants_left = true
            elseif self.moveintent == 1 then
                wants_right = true
            end

            if self.jumpintent == 0 then
                wants_jump = true
            end
        end

        if wants_left then
            self.dx = self.dx - self.dx_accel * dt
            self.is_walking = true
            self.direction = 'left'
            self.spr = self.walk
        end

        if wants_right then
            self.dx = self.dx + self.dx_accel * dt
            self.is_walking = true
            self.direction = 'right'
            self.spr = self.walk
        end

        -- perform jumping if we can/should
        if wants_jump and self.jump_enabled then
            self.dy = self.jump_dy
            self.jump_enabled = false
            self.jumptimer = 1
        end

        -- slow down
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

        -- limit maximum horizontal speed
        if self.dx > self.dx_max then
            self.dx = self.dx_max
        elseif self.dx < -self.dx_max then
            self.dx = -self.dx_max
        end

        -- apply gravity
        self.dy = self.dy + self.gravity * dt

        -- if moving suspiciously vertically then disable jumping
        if math.abs(self.dy) > 20 then
            self.jump_enabled = false
            self.spr = self.jump
        end

        -- resolve new velocity
        -- first, resolve horizontal movement

        self.x = self.x + self.dx * dt
        local collision = obj.get_collisions(self, self.geometry_layer, true)

        self.walked_into_wall = false

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
            self.walked_into_wall = true
        end

        -- now, resolve vertical movement

        self.y = self.y + self.dy * dt
        collision = obj.get_collisions(self, self.geometry_layer, true)

        if collision ~= nil then
            if self.dy >= 0 then
                -- here it's safer to assume dy==0 -> the npc was moving somewhat down-ish
                self.y = collision.y - self.h
                self.jump_enabled = true
            else
                self.y = collision.y + collision.h + 1
            end

            self.dy = 0
        end

    end,
    render = function(self)
        love.graphics.setColor(self.color)
        self.spr:render(math.floor(self.x), math.floor(self.y), 0, self.direction == 'left')
    end,
}
