--- Character component.

local log          = require 'log'
local map          = require 'map'
local object       = require 'object'
local object_group = require 'object_group'
local sprite       = require 'sprite'
local util         = require 'util'

--[[
    Simulates a player-like object.

    The 'character' component does not subscribe to keyboard events on its own.
    Any manual inputs must be manually passed via the 'input_down' and 'input_up' member functions.

    Inputs:
        'left' : move left
        'right' : move right
        'crouch' : crouch
        'jump' : jump
        'throw' : grenade throw

    To bind the inputs to keyboard events, subscribe the parent object to the 'inputdown' and 'inputup' events.
]]--

return {
    init = function(this)
        -- Configuration.
        this.gravity           = this.gravity or 350
        this.crouch_decel      = this.crouch_decel or 1000
        this.passive_decel     = this.passive_decel or 600
        this.midair_decel      = this.midair_decel or 200
        this.jump_dy           = this.jump_dy or -280
        this.dx_accel          = this.dx_accel or 1600
        this.air_accel         = this.air_accel or 800
        this.dx_max            = this.dx_max or 150
        this.grenade_dampening = this.grenade_dampening or 3
        this.color             = this.color or {1, 1, 1, 1}

        -- set character sprites to use
        this.spriteset = this.spriteset or 'char/player/'

        -- load gib sprites
        this.gib_head = this.spriteset .. this.head_dim .. '12x9_head.png'
        this.gib_body = this.spriteset .. this.body_dim .. '12x9_body.png'
        this.gib_arm = this.spriteset .. this.arm_dim .. '12x9_arm.png'
        this.gib_leg = this.spriteset .. this.leg_dim .. '12x9_leg.png'

        -- Gib locations.
        this.gib_config = this.gib_config or {
            head = {
                spr = this.git_head,
                x = 0,
                y = 0,
                follow = true,
            },
            body = {
                spr = this.gib_body,
                x = 8,
                y = 8,
            },
            leg_left = {
                spr = this.gib_leg,
                x = 8,
                y = 22,
            },
            leg_right = {
                spr = this.gib_leg,
                x = 14,
                y = 22,
            },
            arm_left = {
                spr = this.gib_arm,
                x = 8,
                y = 8,
            },
            arm_right = {
                spr = this.gib_arm,
                x = 18,
                y = 8,
            },
        }

        this.w = this.w or 14
        this.h = this.h or 32

        this.spr_offsetx = this.spr_offsetx or -10

        -- Sprites

        this.spr_idle = sprite.create(this.spriteset .. '32x32_idle.png', 32, 32, 0.25)
        this.spr_walk = sprite.create(this.spriteset .. '32x32_walk.png', 32, 32, 0.1)
        this.spr_jump = sprite.create(this.spriteset .. '32x32_jump.png', 32, 32, 0.05)
        this.spr_jump.looping = false

        -- initial sprite
        this.spr = this.spr_idle

        -- State.
        this.dx, this.dy   = 0, 0
        this.jump_enabled  = false
        this.is_walking    = false
        this.direction     = 'right'
        this.nade          = nil
        this.throw_enabled = false
        this.squish        = 0
        this.squishiness   = this.squishiness or 1
        this.squishspeed   = 32 -- pixels per second
    end,

    explode = function(this, _, _, _)
        this.dead = true

        local sprite_left = this.x + this.spr_offsetx

        for _, v in pairs(this.gib_config) do
            local gib = object_group.create_object(this.__layer, 'gib', {
                spr_name = v.spr,
                x = sprite_left + v.x,
                y = this.y + v.y,
                dx = this.dx,
                dy = this.dy,
                flip = (this.direction == 'left'),
                color = this.color,
            })

            if v.follow then
                this.follow_gib = gib
            end
        end
    end,

    inputdown = function(this, key)
        if key == 'left' then
            this.wants_left = true
        elseif key == 'right' then
            this.wants_right = true
        elseif key == 'crouch' and this.jump_enabled then
            this.wants_crouch = true
        elseif key == 'jump' then
            -- Perform a jump if we can.
            if this.jump_enabled then
                this.dy = this.jump_dy
                this.jump_enabled = false
                this.squish = -4 * this.squishiness

                -- Start the jump sprite from the beginning.
                -- It will be switched to in render().
                sprite.play(this.spr_jump)
            end
        elseif key == 'throw' then
            -- Start to throw a nade if we can.
            if this.nade == nil then
                this.nade = object_group.create_object(this.__layer, 'nade', {
                    x = this.x + this.w / 2,
                    y = this.y + this.h / 2,
                })
            end
        elseif key == 'interact' then
            -- Send out interaction events.
            -- Use the containing object as the 'caller' and do not collide with it.

            map.foreach_object(function (other_obj)
                if other_obj ~= this.__parent and util.aabb(this, other_obj) then
                    object.call(other_obj, 'interact', this.__parent)
                end
            end)
        end
    end,

    inputup = function(this, key)
        if key == 'left' then
            this.wants_left = false
        elseif key == 'right' then
            this.wants_right = false
        elseif key == 'throw' then
            -- Throw a grenade if we're holding one.
            if this.nade ~= nil then
                this.nade:throw(this.dx / this.grenade_dampening, this.dy / this.grenade_dampening)
                this.nade = nil
            end
        elseif key == 'jump' then
            if this.dy < 0 then
                this.dy = this.dy / 2
            end
        elseif key == 'crouch' then
            this.wants_crouch = false
        end
    end,

    update = function(this, dt)
        -- Update the current sprite.
        sprite.update(this.spr, dt)

        this.is_walking = false

        -- Compute deceleration amount.
        local decel_amt = this.passive_decel

        -- Update squish state.
        if this.squish < 0 then
            this.squish = math.min(0, this.squish + this.squishspeed * dt)
        elseif this.squish > 0 then
            this.squish = math.max(0, this.squish - this.squishspeed * dt)
        end

        -- Update movement velocities.
        -- if both movement keys are held don't move,
        -- use air/crouch decel to stop quicker
        if this.wants_right and this.wants_left then
            decel_amt = this.crouch_decel
            this.is_walking = false
        elseif this.wants_left then
            this.direction = 'left'

            if this.jump_enabled then
                this.is_walking = true
                this.dx = this.dx - this.dx_accel * dt
            else
                this.dx = this.dx - this.air_accel * dt
            end
        elseif this.wants_right then
            this.direction = 'right'

            if this.jump_enabled then
                this.is_walking = true
                this.dx = this.dx + this.dx_accel * dt
            else
                this.dx = this.dx + this.air_accel * dt
            end
        end

        if this.wants_crouch then
            decel_amt = this.crouch_decel
        elseif not this.jump_enabled then
            decel_amt = this.midair_decel
        end

        -- Perform deceleration.
        if this.dx > 0 then
            this.dx = math.max(this.dx - decel_amt * dt, 0)
        else
            this.dx = math.min(this.dx + decel_amt * dt, 0)
        end

        -- Perform max speed clamping.
        this.dx = math.max(this.dx, -this.dx_max)
        this.dx = math.min(this.dx, this.dx_max)

        -- Apply gravity.
        this.dy = this.dy + dt * this.gravity

        -- Update nade location if we're holding one.
        if this.nade then
            this.nade.x = this.x + this.w / 2
            this.nade.y = this.y + this.h / 2
            this.nade.dx, this.nade.dy = 0, 0
        end

        -- Resolve horizontal motion.
        this.x = this.x + this.dx * dt

        local collision, collision_rect = map.aabb_tile(this)

        if collision then
            if this.dx > 0 then
                this.x = collision_rect.x - this.w
            elseif this.dx < 0 then
                this.x = collision_rect.x + collision_rect.w
            else
                log.debug('Player is in a bad place. Colliding horizontally without moving?')
                log.debug('Player rect: %d %d %d %d (right %d, bottom %d)',
                          this.x, this.y, this.w, this.h, this.x + this.w, this.y + this.h)
                log.debug('Collision rect: %d %d %d %d (right %d, bottom %d)',
                          collision_rect.x, collision_rect.y, collision_rect.w, collision_rect.h,
                          collision_rect.x + collision_rect.w, collision_rect.y + collision_rect.h)
            end

            this.dx = 0
        end

        -- Resolve vertical motion.
        this.y = this.y + this.dy * dt

        collision, collision_rect = map.aabb_tile(this)

        if collision then
            if this.dy >= 0 then
                this.y = collision_rect.y - this.h

                if not this.jump_enabled then
                    this.jump_enabled = true
                    this.squish = this.squishiness * math.max(1, math.log(this.dy)) -- squish
                end
            else
                this.y = collision_rect.y + collision_rect.h
            end

            this.dy = 0
        end

        -- Disable jumping if moving vertically.
        if math.abs(this.dy) > 20 then
            this.jump_enabled = false
        end
    end,

    render = function(this)
        -- Choose the correct sprite.
        if this.is_walking then
            this.spr = this.spr_walk
        elseif this.jump_enabled then
            this.spr = this.spr_idle
        else
            this.spr = this.spr_jump
        end

        -- Apply the appropriate color.
        love.graphics.setColor(this.color)

        -- Render the current sprite.
        sprite.render(
            this.spr,
            this.x + this.spr_offsetx,
            this.y + this.squish,
            0,
            this.direction == 'left',
            this.squish
        )
    end,
}
