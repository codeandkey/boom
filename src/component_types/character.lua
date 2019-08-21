--- Character component.

local log            = require 'log'
local map            = require 'map'
local object         = require 'object'
local object_group   = require 'object_group'
local sprite         = require 'sprite'
local physics_groups = require 'physics_groups'
local util           = require 'util'

--[[
    Simulates a player-like object.

    The 'character' component does not subscribe to keyboard events on its own.
    Any manual inputs must be manually passed via the 'input_down' and 'input_up' member functions.

    Inputs:
        'left' : move left
        'right' : move right
        'down' : crouch
        'up'   : aim up
        'jump' : jump
        'throw' : grenade throw

    To bind the inputs to keyboard events, subscribe the parent object to the 'inputdown' and 'inputup' events.
]]--

return {
    init = function(this)
        -- Configuration.
        this.gravity             = this.gravity or 350
        this.crouch_decel        = this.crouch_decel or 600
        this.passive_decel       = this.passive_decel or 400
        this.midair_decel        = this.midair_decel or 200
        this.jump_dy             = this.jump_dy or -280
        this.dx_accel            = this.dx_accel or 1600
        this.dx_max              = this.dx_max or 150
        this.grenade_dampening   = this.grenade_dampening or 3
        this.color               = this.color or {1, 1, 1, 1}
        this.rope_color          = this.rope_color or {0.2, 0.2, 0.2, 1}
        this.num_rope_segments   = this.num_rope_segments or 5
        this.rope_segment_length = 16
        this.rope_point_radius   = 2
        this.throw_pitch_speed  = 20 -- higher values make the player aim up/down faster
        this.throw_strength     = this.throw_strength or 40

        this.w = this.w or 14
        this.h = this.h or 32

        this.spr_offsetx = this.spr_offsetx or -10

        -- Sprites

        this.spr_idle = this.spr_idle or sprite.create('32x32_player.png', 32, 32, 0.25)
        this.spr_walk = this.spr_walk or sprite.create('32x32_player-walk.png', 32, 32, 0.1)
        this.spr_jump = this.spr_jump or sprite.create('32x32_player-jump.png', 32, 32, 0.05)
        this.spr_jump.looping = false
        this.spr = this.spr_idle

        -- State.
        this.dx, this.dy   = 0, 0
        this.jump_enabled  = false
        this.is_walking    = false
        this.direction     = 'right'
        this.nade          = nil
        this.throw_enabled = false
        this.throw_pitch   = 0 -- radians
        this.target_pitch  = 0

        -- Physics control.
        this.body = love.physics.newBody(map.get_physics_world(), 0, 0, 'kinematic')
    end,

    explode = function(this, _, _, _)
        this.dead = true

        local sprite_left = this.x + this.spr_offsetx

        object_group.create_object(this.__layer, 'gib', {
            spr_name = '12x9_player_head.png',
            x = sprite_left + 11,
            y = this.y,
            color = this.color,
        })

        object_group.create_object(this.__layer, 'gib', {
            spr_name = '14x13_player_body.png',
            x = sprite_left + 8,
            y = this.y + 8,
            color = this.color,
        })

        object_group.create_object(this.__layer, 'gib', {
            spr_name = '5x9_player_leg.png',
            x = sprite_left + 14,
            y = this.y + 22,
            color = this.color,
        })

        object_group.create_object(this.__layer, 'gib', {
            spr_name = '5x9_player_leg.png',
            x = sprite_left + 18,
            y = this.y + 22,
            color = this.color,
        })

        object_group.create_object(this.__layer, 'gib', {
            spr_name = '6x13_player_arm.png',
            x = sprite_left + 8,
            y = this.y + 8,
            color = this.color,
        })

        object_group.create_object(this.__layer, 'gib', {
            spr_name = '6x13_player_arm.png',
            x = sprite_left + 18,
            y = this.y + 8,
            color = this.color,
        })
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
                -- Create a new nade.
                this.nade = object_group.create_object(this.__layer, 'nade', {
                    x = this.x + this.w / 2,
                    y = this.y + this.h / 2,
                    holding_body = this.body,
                    on_destroy = function()
                        -- Destroy the player's rope objects.
                        this.nade = nil

                        for _, v in ipairs(this.rope_segment_joints) do
                            v:release()
                        end

                        for _, v in ipairs(this.rope_segments) do
                            v.fixture:release()
                            v.body:release()
                            v.shape:release()
                        end

                        this.rope_segments = {}
                        this.rope_segment_joints = {}
                    end,
                })

                local vx, vy = math.cos(this.throw_angle), math.sin(this.throw_angle)

                vx = vx * this.throw_strength + this.dx / this.grenade_dampening
                vy = vy * this.throw_strength + this.dy / this.grenade_dampening

                this.nade:throw(vx, vy)

                -- Create distance joint holding nade.
                this.nade_joint = love.physics.newRopeJoint(this.body,
                                                            this.nade.body,
                                                            this.x + this.w / 2,
                                                            this.y + this.h / 2,
                                                            this.x + this.w / 2,
                                                            this.y + this.h / 2,
                                                            this.num_rope_segments * this.rope_segment_length,
                                                            false)

                -- Create fake rope.
                this.rope_segments = {}
                this.rope_segment_joints = {}

                for i=1,this.num_rope_segments do
                    -- Initialize segment physics bits.
                    local segment_shape = love.physics.newCircleShape(this.rope_point_radius)
                    local segment_body = love.physics.newBody(map.get_physics_world(), this.x + this.w / 2, this.y + this.h / 2, 'dynamic')
                    local segment_fixture = love.physics.newFixture(segment_body, segment_shape, 1)

                    -- Disable collisions with physics objects.
                    segment_fixture:setCategory(physics_groups.ROPE)
                    segment_fixture:setMask(physics_groups.WORLD, physics_groups.GIB, physics_groups.ROPE)

                    table.insert(this.rope_segments, {
                        body = segment_body,
                        shape = segment_shape,
                        fixture = segment_fixture,
                    })
                end

                log.debug('Created %d rope sgements.', this.num_rope_segments)

                -- Attach rope segments together.
                for i=1,this.num_rope_segments-1 do
                    local joint = love.physics.newRopeJoint(this.rope_segments[i].body, this.rope_segments[i+1].body,
                                                            this.x + this.w / 2, this.y + this.h / 2,
                                                            this.x + this.w / 2, this.y + this.h / 2,
                                                            this.rope_segment_length)
                    table.insert(this.rope_segment_joints, joint)
                end

                -- Attach player to first segment.
                table.insert(this.rope_segment_joints, love.physics.newRopeJoint(
                    this.body, this.rope_segments[1].body,
                    this.x + this.w / 2, this.y + this.h / 2,
                    this.x + this.w / 2, this.y + this.h / 2,
                    this.rope_segment_length
                ))

                -- Attach nade to last segment.
                table.insert(this.rope_segment_joints, love.physics.newRopeJoint(
                    this.rope_segments[#this.rope_segments].body, this.nade.body,
                    this.x + this.w / 2, this.y + this.h / 2,
                    this.x + this.w / 2, this.y + this.h / 2,
                    this.rope_segment_length
                ))
            end
        elseif key == 'interact' then
            -- Send out interaction events.
            -- Use the containing object as the 'caller' and do not collide with it.

            map.foreach_object(function (other_obj)
                if other_obj ~= this.__parent and util.aabb(this, other_obj) then
                    object.call(other_obj, 'interact', this.__parent)
                end
            end)
        elseif key == 'up' then
            this.wants_up = true
        elseif key == 'down' then
            this.wants_down = true
        end
    end,

    inputup = function(this, key)
        if key == 'left' then
            this.wants_left = false
        elseif key == 'right' then
            this.wants_right = false
        elseif key == 'throw' then
            -- Detonate any swinging grenades.
            if this.nade then
                object.destroy(this.nade)
            end
        elseif key == 'jump' then
            if this.dy < 0 then
                this.dy = this.dy / 2
            end
        elseif key == 'up' then
            this.wants_up = false
        elseif key == 'down' then
            this.wants_down = false
        end
    end,

    update = function(this, dt)
        -- Update the current sprite.
        sprite.update(this.spr, dt)

        this.is_walking = false

        -- Compute deceleration amount.
        local decel_amt = this.passive_decel

        -- Update movement velocities.
        -- if both movement keys are held don't move,
        -- use air/crouch decel to stop quicker
        if this.wants_right and this.wants_left then
            decel_amt = this.midair_decel
            this.is_walking = false
        elseif this.wants_left then
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

        -- Disable jumping if moving vertically.
        if math.abs(this.dy) > 20 then
            this.jump_enabled = false
        end

        -- Update phys body with character center.
        this.body:setPosition(this.x + this.w / 2, this.y + this.h / 2)

        -- Decide what direction the player will aim.
        -- A directional switch should apply immediately, so we only animate the 'pitch' of the angle.

        if this.wants_up and not this.wants_down then
            if this.wants_left or this.wants_right then
                this.target_pitch = -3.141 / 4.0
            else
                this.target_pitch = -3.141 / 2.0
            end
        elseif this.wants_down and not this.wants_up then
            if this.wants_left or this.wants_right then
                this.target_pitch = 3.141 / 4.0
            else
                this.target_pitch = 3.141 / 2.0
            end
        else
            this.target_pitch = 0
        end

        -- Animate player pitch to target.
        if this.throw_pitch < this.target_pitch then
            this.throw_pitch = math.min(this.throw_pitch + dt * this.throw_pitch_speed, this.target_pitch)
        elseif this.throw_pitch > this.target_pitch then
            this.throw_pitch = math.max(this.throw_pitch - dt * this.throw_pitch_speed, this.target_pitch)
        end

        -- Compute actual throw angle.
        if this.direction == 'right' then
            this.throw_angle = this.throw_pitch
        else
            this.throw_angle = 3.141 - this.throw_pitch
        end
    end,

    render = function(this)
        -- Make sure to not render any sprites for dead characters.
        if this.dead then
            return
        end

        -- Choose the correct sprite.
        if this.is_walking then
            this.spr = this.spr_walk
        elseif this.jump_enabled then
            this.spr = this.spr_idle
        else
            this.spr = this.spr_jump
        end

        -- Render the grenade rope.
        if this.nade then
            love.graphics.setColor(this.rope_color)
            love.graphics.setLineWidth(1)

            -- Render rope joint lines.
            for _, v in ipairs(this.rope_segment_joints) do
                local ba, bb = v:getBodies()
                local bax, bay = ba:getPosition()
                local bbx, bby = bb:getPosition()

                love.graphics.line(bax, bay, bbx, bby)
            end
        end

        -- Apply the appropriate color.
        love.graphics.setColor(this.color)

        -- Render the current sprite.
        sprite.render(this.spr, math.floor(this.x + this.spr_offsetx), math.floor(this.y), 0, this.direction == 'left')

        -- Render debug throw indicator
        -- REMOVEME eventually, should be replaced with a better indicator or hint

        if this.__parent.name == 'player' then
            love.graphics.setColor(1, 1, 1, 0.4)
            love.graphics.line(this.x + this.w / 2, this.y + this.h / 2,
                               this.x + this.w / 2 + 16 * math.cos(this.throw_angle),
                               this.y + this.h / 2 + 16 * math.sin(this.throw_angle))
        end
    end,
}
