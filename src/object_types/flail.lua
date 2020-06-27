--- Flail weapon.

local object = require 'object'
local map    = require 'map'
local sprite = require 'sprite'
local camera = require 'camera'
local physics_groups = require 'physics_groups'

return {
    init = function(this)
        -- Flail should not be created on its own.
        -- Expected parameters:
        --   dx: should match throwing player
        --   dy: should match throwing player
        --   thrower: should point to character component

        -- Configuration
        this.damage     = this.damage or 45
        this.dx         = this.dx or 0
        this.dy         = this.dy or 0
        this.gravity    = this.gravity or 156.8
        this.fade_speed = 3
        this.idle_wait  = 3
        this.smashspeed = 140
        this.rope_length = 75
        this.trail_len = 7

        -- seconds to stand still after smashing something
        this.postsmash_wait = this.postsmash_wait or 0.5

        -- Resources
        this.spr = sprite.create('obj/16x16_flail.png', 16, 16, 0)
        this.spr_smash = sprite.create('obj/16x16_flail_smash.png', 16, 16, 0)
        this.spr_link = sprite.create('obj/6x3_flail_link.png', 6, 3, 0)
        this.w = 16
        this.h = 16

        -- Physics elements
        this.shape = love.physics.newRectangleShape(this.w, this.h)
        this.body = love.physics.newBody(map.get_physics_world(), this.x, this.y, 'dynamic')
        this.fixture = love.physics.newFixture(this.body, this.shape, 1)

        this.body:applyLinearImpulse(this.dx, this.dy)
        this.fixture:setFriction(0.9)
        this.fixture:setGroupIndex(physics_groups.FLAIL)
        this.fixture:setMask(-physics_groups.FLAIL_CHAIN)

        -- Create a tether
        this.tether_shape = love.physics.newRectangleShape(1, 1)
        this.tether_body = love.physics.newBody(map.get_physics_world(), this.thrower.x + this.thrower.w / 2, this.thrower.y + this.thrower.h / 2, 'kinematic')
        this.tether_fixture = love.physics.newFixture(this.tether_body, this.tether_shape, 1)
        this.tether_fixture:setGroupIndex(physics_groups.FLAIL_CHAIN)

        -- Link flail to tether
        this.rope_joint = love.physics.newRopeJoint(this.body, this.tether_body, this.x, this.y, this.thrower.x + this.thrower.w / 2, this.thrower.y + this.thrower.h / 2, this.rope_length, false)

        -- Create rope links
        --[[
        this.num_ropelinks = math.floor(this.rope_length / 4)
        this.ropelinks = {}

        this.ropelink_shape = love.physics.newRectangleShape(6, 3)
        this.ropelink_joints = {}

        for i=1,this.num_ropelinks do
            this.ropelinks[i] = {}
            this.ropelinks[i].body = love.physics.newBody(map.get_physics_world(), this.x, this.y, 'dynamic')
            this.ropelinks[i].fixture = love.physics.newFixture(this.ropelinks[i].body, this.ropelink_shape, 1)
            this.ropelinks[i].fixture:setGroupIndex(physics_groups.FLAIL_CHAIN)
            this.ropelinks[i].fixture:setMask(physics_groups.FLAIL)

            if i > 1 then
                table.insert(this.ropelink_joints, love.physics.newRopeJoint(this.ropelinks[i].body, this.ropelinks[i - 1].body, this.x + 2, this.y, this.x - 2, this.y, 1, false))
            end

            if i == 1 then
                table.insert(this.ropelink_joints, love.physics.newRopeJoint(this.ropelinks[i].body, this.tether_body, this.x + 3, this.y, this.x, this.y, 0, false))
            end

            if i == this.num_ropelinks then
                table.insert(this.ropelink_joints, love.physics.newRopeJoint(this.ropelinks[i].body, this.body, this.x + 2, this.y, this.x, this.y, 1, false))
            end
        end
        ]]--

        -- Manipulation
        this.smash = function(self, vx, vy)
            if self.in_smash then
                return
            end

            self.alpha = 1
            self.in_smash = true
            self.in_trail = true
            self.body:applyLinearImpulse(vx * self.smashspeed, vy * self.smashspeed)
        end

        -- State
        this.in_smash = false
        this.in_trail = false
        this.did_bcast = false
        this.postsmash_timer = 0
        this.alpha = 1
        this.trail = {}
    end,

    destroy = function(this)
        --[[
        for i=1,this.num_ropelinks do
            this.ropelink_joints[i]:destroy()
            this.ropelinks[i].fixture:destroy()
            this.ropelinks[i].body:destroy()
        end

        this.ropelink_shape:destroy()
        ]]--

        this.rope_joint:destroy()
        this.tether_fixture:destroy()
        this.tether_shape:release()
        this.tether_body:destroy()
        this.fixture:destroy()
        this.body:destroy()
        this.shape:release()
        this.thrower:expire_flail()
    end,

    update = function(this, dt)
        this.idle_wait = this.idle_wait - dt

        this.tether_body:setPosition(this.thrower.x + this.thrower.w / 2, this.thrower.y + this.thrower.h / 2)

        if this.in_smash then
            table.insert(this.trail, 1, {
                x = this.body:getX(),
                y = this.body:getY(),
                angle = this.body:getAngle(),
            })

            this.trail[this.trail_len + 1] = nil
        end

        local did_collide = false

        for _, v in ipairs(this.body:getContacts()) do
            local first, second = v:getFixtures()
            if first:getGroupIndex() == physics_groups.WORLD or second:getGroupIndex() == physics_groups.WORLD then
                did_collide = true
            end
        end

        -- If in a smash and collided, broadcast the event and start the timer
        if did_collide then
            if this.in_smash then
                if not this.did_bcast then
                    -- TODO: broadcast smash event to notify interactable objects
                    this.did_bcast = true
                    this.in_trail = false
                    this.postsmash_timer = this.postsmash_wait

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

        this.x, this.y = this.body:getPosition()
        this.angle = this.body:getAngle()
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

        local tx, ty = this.tether_body:getPosition()
        local x, y = this.body:getPosition()

        local d = 4
        local ang = math.atan2(ty - y, tx - x)

        local cx, cy = x, y
        local dist = math.sqrt(math.pow(x - tx, 2) + math.pow(y - ty, 2))
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
                    sprite.render(this.spr_smash, v.x - this.w / 2, v.y - this.h / 2, v.angle)
                end
            end

            sprite.render(this.spr_smash, this.x - this.w / 2, this.y - this.h / 2, this.angle)
        else
            sprite.render(this.spr, this.x - this.w / 2, this.y - this.h / 2, this.angle)
        end
    end,
}
