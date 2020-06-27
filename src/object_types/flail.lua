--- Flail weapon.

local object = require 'object'
local map    = require 'map'
local sprite = require 'sprite'
local camera = require 'camera'
local physics_groups = require 'physics_groups'
local util = require 'util'
local object_group = require 'object_group'
local log = require 'log'

return {
    init = function(this)
        -- Flail should not be created on its own.
        -- Expected parameters:
        --   dx: should match throwing player
        --   dy: should match throwing player
        --   thrower: should point to character component

        -- Configuration
        this.damage     = this.damage or 45
        this.gravity    = this.gravity or 357.8
        this.fade_speed = 3
        this.idle_wait  = 3
        this.smashspeed = 500
        this.throwspeed = 120
        this.rope_length = 120
        this.trail_len = 7
        this.angle = 0
        this.friction = 0.7
        this.vx = this.vx or 0
        this.vy = this.vy or 1
        this.rope_strength = 0.2

        -- seconds to stand still after smashing something
        this.postsmash_wait = this.postsmash_wait or 0.5

        -- Resources
        this.spr = sprite.create('obj/16x16_flail.png', 16, 16, 0)
        this.spr_smash = sprite.create('obj/16x16_flail_smash.png', 16, 16, 0)
        this.spr_link = sprite.create('obj/6x3_flail_link.png', 6, 3, 0)
        this.w = 16
        this.h = 16

        -- Manipulation
        this.smash = function(self, vx, vy)
            if self.in_smash then
                return
            end

            self.alpha = 1
            self.in_smash = true
            self.in_trail = true
            self.dx = self.dx / 5 + vx * self.smashspeed
            self.dy = self.dy / 5 + vy * self.smashspeed
        end

        -- State
        this.in_smash = false
        this.in_trail = false
        this.did_bcast = false
        this.postsmash_timer = 0
        this.alpha = 1
        this.trail = {}
        this.rotation = (math.random() - 0.5) * 2.0
        this.dx = this.vx * this.throwspeed + this.thrower.dx
        this.dy = this.vy * this.throwspeed + this.thrower.dy
    end,

    destroy = function(this)
        this.thrower:expire_flail()
    end,

    update = function(this, dt)
        this.idle_wait = this.idle_wait - dt
        this.angle = this.angle + this.rotation * dt
        this.dy = this.dy + this.gravity * dt

        if this.in_smash then
            table.insert(this.trail, 1, {
                x = this.x,
                y = this.y,
                angle = this.angle,
            })

            this.trail[this.trail_len + 1] = nil
        end

        local did_collide = false

        -- Run horizontal collision
        local hbox = {
            x = this.x + dt * this.dx,
            y = this.y,
            w = this.w,
            h = this.h,
        }

        local col, cbox = map.aabb_tile(hbox)

        if col then
            this.angle = 0
            this.rotation = 0
            did_collide = true

            this.dy = this.friction * this.dy

            if this.dx > 0 then
                this.x = cbox.x - this.w
            elseif this.dx < 0 then
                this.x = cbox.x + cbox.w
            end

            this.dx = 0
        else
            this.x = this.x + dt * this.dx
        end

        -- Run vertical collision
        local vbox = {
            x = this.x,
            y = this.y + dt * this.dy,
            w = this.w,
            h = this.h,
        }

        col, cbox = map.aabb_tile(vbox)

        if col then
            log.debug('colliding y, this LRTB (%f %f %f %f), cbox LRTB (%f %f %f %f), dy %f', this.x, this.x + this.w, this.y, this.y + this.h, cbox.x, cbox.x + cbox.w, cbox.y, cbox.y + cbox.h, this.dy)
            this.angle = 0
            this.rotation = 0
            did_collide = true

            this.dx = this.friction * this.dx

            if this.dy > 0 then
                this.y = cbox.y - this.h
            elseif this.dy < 0 then
                this.y = cbox.y + cbox.h
            end

            this.dy = 0
        else
            this.y = this.y + dt * this.dy
        end

        --[[
        -- Clamp position to maintain rope, this could cause UB if the player reeeally tries
        local center = object.center(this)
        local thrower_center = object.center(this.thrower)

        local clamp_angle = math.atan2(center.y - thrower_center.y, center.x - thrower_center.x)
        local clamp_x = math.cos(clamp_angle) * this.rope_length + thrower_center.x

        if center.x < thrower_center.x then
            if center.x + dt * this.dx <= clamp_x then
                this.dx = 0
                this.x = clamp_x
            end
        elseif center.x > thrower_center.x then
            if center.x + dt * this.dx >= clamp_x then
                this.dx = 0
                this.x = clamp_x
            end
        end
        ]]--


        local center = object.center(this)
        local thrower_center = object.center(this.thrower)

        local dist = math.sqrt(math.pow(center.x - thrower_center.x, 2) + math.pow(center.y - thrower_center.y, 2))
        local ang = math.atan2(center.y - thrower_center.y, center.x - thrower_center.x)

        log.debug('dist = %f, ang = %f', dist, ang)

        if dist > this.rope_length then
            local targetx, targety = math.cos(ang) * this.rope_length + thrower_center.x, math.sin(ang) * this.rope_length + thrower_center.y

            this.dx = this.dx + (targetx - center.x) * this.rope_strength
            this.dy = this.dy + (targety - center.y) * this.rope_strength
        end

        --[[

        -- No circular clamping for y. Just use linear bounds
        if this.y + this.h / 2 >= thrower_center.y + this.rope_length then
            this.y = thrower_center.y + this.rope_length - this.h / 2
            this.dy = 0
        elseif this.y + this.h / 2 <= thrower_center.y - this.rope_length then
            this.y = thrower_center.y - this.rope_length - this.h / 2
            this.dy = 0
        end

        if this.x + this.w / 2 >= thrower_center.x + this.rope_length then
            this.x = thrower_center.x + this.rope_length - this.w / 2
            this.dx = 0
        elseif this.x + this.w / 2 <= thrower_center.x - this.rope_length then
            this.x = thrower_center.x - this.rope_length - this.w / 2
            this.dx = 0
        end]]--

        --[[center = object.center(this)
        thrower_center = object.center(this.thrower)
        clamp_angle = math.atan2(center.y - thrower_center.y, center.x - thrower_center.x)
        local clamp_y = math.sin(clamp_angle) * this.rope_length + thrower_center.y

        if center.y < thrower_center.y then
            if center.y + dt * this.dy <= clamp_y then
                this.dy = 0
                this.y = clamp_y
            end
        elseif center.y > thrower_center.y then
            if center.y + dt * this.dy >= clamp_y then
                this.dy = 0
                this.y = clamp_y
            end
        end]]--

        -- If in a smash and collided, broadcast the event and start the timer
        if did_collide then
            if this.in_smash then
                if not this.did_bcast then
                    this.did_bcast = true
                    this.in_trail = false
                    this.postsmash_timer = this.postsmash_wait

                    object_group.create_object(this.__layer, 'explosion', {
                        x = this.x,
                        y = this.y
                    })

                    --[[map.foreach_object(function (other_obj)
                        if other_obj ~= this and other_obj.__typename ~= 'player' and util.aabb(other_obj, this) then
                            object.call(other_obj, 'explode', 100, (other_obj.x - this.x) / 30, (other_obj.y - this.y) / 30, 30)
                        end
                    end)]]--

                    camera.setshake(0.1)
                end

                this.dx = 0
                this.dy = 0
            end
        end

        -- If idle for too long, fade out
        if not this.in_smash and this.idle_wait < 0 then
            this.alpha = this.alpha - dt * this.fade_speed

            if this.alpha < 0 then
                object.destroy(this)
            end
        end

        if this.did_bcast then
            this.postsmash_timer = this.postsmash_timer - dt

            if this.postsmash_timer < 0 then
                -- Start fading out.

                this.alpha = this.alpha - this.fade_speed * dt

                if this.alpha < 0 then
                    object.destroy(this)
                end
            end
        end
    end,

    render = function(this)
        love.graphics.setColor({1, 1, 1, this.alpha})

        --[[
        for _, v in ipairs(this.ropelinks) do
            local x, y = v.body:getPosition()
            local rot = v.body:getAngle()

            sprite.render(this.spr_link, x, y, rot)
        end
        ]]--

        local source = object.center(this.thrower)
        local dest = object.center(this)

        local d = 4
        local ang = math.atan2(source.y - dest.y, source.x - dest.x)

        local cx, cy = dest.x, dest.y
        local dist = math.sqrt(math.pow(source.x - dest.x, 2) + math.pow(source.y - dest.y, 2))
        local num = dist / d

        for i=1,num do
            sprite.render(this.spr_link, cx, cy, ang)
            cx = cx + d * math.cos(ang)
            cy = cy + d * math.sin(ang)
        end

        if this.in_smash then
            if this.in_trail then
                -- render trail
                for n, v in ipairs(this.trail) do
                    love.graphics.setColor(1, 1, 1, 1 / n)
                    sprite.render(this.spr_smash, v.x, v.y, v.angle)
                end
            end

            sprite.render(this.spr_smash, this.x, this.y, this.angle)
        else
            sprite.render(this.spr, this.x, this.y, this.angle)
        end
    end,
}
