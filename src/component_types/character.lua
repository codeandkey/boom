--- Character component.

local log          = require 'log'
local map          = require 'map'
local object_group = require 'object_group'
local sprite       = require 'sprite'

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
        log.debug('Initializing character component!')

        -- Configuration.
        this.gravity           = this.gravity or 350
        this.crouch_decel      = this.crouch_decel or 600
        this.passive_decel     = this.passive_decel or 400
        this.midair_decel      = this.midair_decel or 200
        this.jump_dy           = this.jump_dy or -180
        this.dx_accel          = this.dx_accel or 1600
        this.dx_max            = this.dx_max or 150
        this.grenade_dampening = this.grenade_dampening or 3
        this.color             = this.color or {1, 1, 1, 1}

        this.w = this.w or 14
        this.h = this.h or 32

        this.spr_offsetx = this.spr_offsetx or -10

        -- Sprites.
        this.spr_idle = sprite.create('32x32_player.png', 32, 32, 0.25)
        this.spr_walk = sprite.create('32x32_player-walk.png', 32, 32, 0.1)
        this.spr_jump = sprite.create('32x32_player-jump.png', 32, 32, 0.05)

        this.spr_jump.looping = false
        this.spr = this.spr_idle

        -- State.
        this.dx, this.dy   = 0, 0
        this.jump_enabled  = false
        this.is_walking    = false
        this.direction     = 'right'
        this.nade          = nil
        this.throw_enabled = false
    end,

    inputdown = function(this, key)
        if key == 'left' then
            this.wants_left = true
        elseif key == 'right' then
            this.wants_right = true
        elseif key == 'jump' then
            -- Perform a jump if we can.
            if this.jump_enabled then
                this.dy = this.jump_dy
                this.jump_enabled = false

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
        end
    end,

    update = function(this, dt)
        -- Update the current sprite.
        sprite.update(this.spr, dt)

        this.is_walking = false

        -- Update movement velocities.
        if this.wants_left then
            this.dx = this.dx - this.dx_accel * dt
            this.direction = 'left'

            if this.jump_enabled then
                this.is_walking = true
            end
        elseif this.wants_right then
            this.dx = this.dx + this.dx_accel * dt
            this.direction = 'right'

            if this.jump_enabled then
                this.is_walking = true
            end
        end

        -- Compute deceleration amount.
        local decel_amt = this.passive_decel

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
                this.jump_enabled = true
            else
                this.y = collision_rect.y + collision_rect.h
            end

            this.dy = 0
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
        sprite.render(this.spr, this.x + this.spr_offsetx, this.y, 0, this.direction == 'left')
    end,

    destroy = function(_)
        log.debug('Destroying character component!')
    end
}
