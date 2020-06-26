--- Explosion effect.
-- Renders all visual elements of an explosion and then dissappears.

local object = require 'object'
local util = require 'util'
local map = require 'map'

return {
    init = function(this)
        this.num_smoke_particles = this.num_smoke_particles or math.random(32, 80)

        this.smoke_alpha_decay_min = 0.7
        this.smoke_alpha_decay_max = 1
        this.smoke_alpha_min = 0.5
        this.smoke_alpha_max = 1
        this.smoke_rotation_min = -1.3
        this.smoke_rotation_max = 1.3
        this.smoke_dx_min = -50
        this.smoke_dx_max = 50
        this.smoke_dy_min = -100
        this.smoke_dy_max = -20
        this.smoke_size_min = 4
        this.smoke_size_max = 9
        this.smoke_radius_max = 32

        this.num_shrap_particles = this.num_shrap_particles or math.random(24, 32)

        this.shrap_alpha_decay_min = 4
        this.shrap_alpha_decay_max = 6
        this.shrap_alpha_min = 0.5
        this.shrap_alpha_max = 1
        this.shrap_speed_min = 400
        this.shrap_speed_max = 800
        this.shrap_size_min = 16
        this.shrap_size_max = 48
        this.shrap_width_min = 0.1
        this.shrap_width_max = 0.5
        this.shrap_radius_max = 4

        this.num_dirt_particles = this.num_dirt_particles or math.random(32, 64)

        this.dirt_alpha_decay_min = 0.15
        this.dirt_alpha_decay_max = 0.3
        this.dirt_rotation_min = -4
        this.dirt_rotation_max = 4
        this.dirt_alpha_min = 0.75
        this.dirt_alpha_max = 1
        this.dirt_dx_min = 0 -- can be negated if facing left
        this.dirt_dx_max = 200
        this.dirt_dy_min = -200
        this.dirt_dy_max = -50
        this.dirt_size_min = 1
        this.dirt_size_max = 3
        this.dirt_radius_max = 10
        this.dirt_gravity = 156.8 -- 9.8 m/s^2 * 16 px/m
        this.dirt_friction = 40

        this.smoke_particles = {}
        for i=1,this.num_smoke_particles do
            local ang = math.random() * 2.0 * 3.141
            local rad = math.random() * this.smoke_radius_max

            this.smoke_particles[i] = {
                rotspeed = util.randrange(this.smoke_rotation_min, this.smoke_rotation_max),
                alpha_decay = util.randrange(this.smoke_alpha_decay_min, this.smoke_alpha_decay_max),
                x = this.x + math.cos(ang) * rad,
                y = this.y + math.sin(ang) * rad,
                ang = math.random() * 2.0 * 3.141,
                alpha = util.randrange(this.smoke_alpha_min, this.smoke_alpha_max),
                dx = util.randrange(this.smoke_dx_min, this.smoke_dx_max),
                dy = util.randrange(this.smoke_dy_min, this.smoke_dy_max),
                size = util.randrange(this.smoke_size_min, this.smoke_size_max),
            }
        end

        this.shrap_particles = {}
        for i=1,this.num_shrap_particles do
            local ang = math.random() * 2.0 * 3.141
            local rad = math.random() * this.shrap_radius_max

            this.shrap_particles[i] = {
                speed = util.randrange(this.shrap_speed_min, this.shrap_speed_max),
                alpha_decay = util.randrange(this.shrap_alpha_decay_min, this.shrap_alpha_decay_max),
                x = this.x + math.cos(ang) * rad,
                y = this.y + math.sin(ang) * rad,
                ang = ang,
                alpha = util.randrange(this.shrap_alpha_min, this.shrap_alpha_max),
                size = util.randrange(this.shrap_size_min, this.shrap_size_max),
                width = util.randrange(this.shrap_width_min, this.shrap_width_max),
            }
        end

        this.dirt_particles = {}
        for i=1,this.num_dirt_particles do
            local ang = math.random() * 2.0 * 3.141
            local rad = math.random() * this.shrap_radius_max
            local dir = 1

            if math.random(2) == 1 then
                dir = -1
            end

            this.dirt_particles[i] = {
                rotspeed = util.randrange(this.dirt_rotation_min, this.dirt_rotation_max),
                dx = util.randrange(this.dirt_dx_min, this.dirt_dx_max) * dir,
                dy = util.randrange(this.dirt_dy_min, this.dirt_dy_max),
                alpha_decay = util.randrange(this.dirt_alpha_decay_min, this.dirt_alpha_decay_max),
                x = this.x + math.cos(ang) * rad,
                y = this.y + math.sin(ang) * rad,
                ang = ang,
                alpha = util.randrange(this.dirt_alpha_min, this.dirt_alpha_max),
                size = util.randrange(this.dirt_size_min, this.dirt_size_max),
            }
        end
    end,

    update = function(this, dt)
        local live = false

        for i=1,this.num_smoke_particles do
            local v = this.smoke_particles[i]

            v.x = v.x + dt * v.dx
            v.y = v.y + dt * v.dy
            v.ang = v.ang + dt * v.rotspeed
            v.alpha = v.alpha - dt * v.alpha_decay

            if v.alpha > 0 then
                live = true
            end
        end

        for i=1,this.num_shrap_particles do
            local v = this.shrap_particles[i]

            local x2 = v.x + math.cos(v.ang) * v.size
            local y2 = v.y + math.sin(v.ang) * v.size

            local left = math.min(v.x, x2)
            local right = math.max(v.x, x2)
            local top = math.min(v.y, y2)
            local bottom = math.max(v.y, y2)

            if map.aabb_tile({
                x = left,
                y = top,
                w = (right - left),
                h = (bottom - top),
            }) then
                v.alpha = 0
            end

            v.x = v.x + math.cos(v.ang) * dt * v.speed
            v.y = v.y + math.sin(v.ang) * dt * v.speed

            v.alpha = v.alpha - dt * v.alpha_decay

            if v.alpha > 0 then
                live = true
            end
        end

        for i=1,this.num_dirt_particles do
            local v = this.dirt_particles[i]

            -- perform light aabb collisions
            local hbox = {
                x = v.x + dt * v.dx,
                y = v.y,
                w = 1,
                h = 1,
            }

            local collision, crect = map.aabb_tile(hbox)

            if collision then
                if v.dx < 0 then
                    v.x = crect.x + crect.w + 1
                elseif v.dx > 0 then
                    v.x = crect.x - 1
                end

                v.dx = 0
                v.rotspeed = 0

                if v.dy > 0 then
                    v.dy = math.max(v.dy - dt * this.dirt_friction, 0)
                else
                    v.dy = math.min(v.dy + dt * this.dirt_friction, 0)
                end
            else
                v.x = v.x + dt * v.dx
            end

            local vbox = {
                x = v.x,
                y = v.y + dt * v.dy,
                w = 1,
                h = 1,
            }

            collision, crect = map.aabb_tile(vbox)

            if collision then
                if v.dy > 0 then
                    v.y = crect.y - 1
                elseif v.dy < 0 then
                    v.y = crect.y + crect.h + 1
                end

                v.dy = 0
                v.rotspeed = 0

                if v.dx > 0 then
                    v.dx = math.max(v.dx - dt * this.dirt_friction, 0)
                else
                    v.dx = math.min(v.dx + dt * this.dirt_friction, 0)
                end
            else
                v.y = v.y + dt * v.dy
            end

            v.dy = v.dy + dt * this.dirt_gravity
            v.ang = v.ang + dt * v.rotspeed
            v.alpha = v.alpha - dt * v.alpha_decay

            if v.alpha > 0 then
                live = true
            end
        end

        if not live then
            object.destroy(this)
        end
    end,

    render = function(this)
        for i=1,this.num_smoke_particles do
            local v = this.smoke_particles[i]

            love.graphics.push()
            love.graphics.setColor({v.alpha / 2, v.alpha / 2, v.alpha / 2, v.alpha})
            love.graphics.translate(v.x, v.y)
            love.graphics.rotate(v.ang)
            love.graphics.rectangle('fill', - v.size / 2, - v.size / 2, v.size, v.size)
            love.graphics.pop()
        end

        for i=1,this.num_shrap_particles do
            local v = this.shrap_particles[i]
            local x1 = v.x
            local y1 = v.y
            local x2 = v.x + math.cos(v.ang) * v.size
            local y2 = v.y + math.sin(v.ang) * v.size

            love.graphics.setColor({1, 1, 1, v.alpha})
            love.graphics.setLineWidth(v.width)
            love.graphics.line({x1, y1, x2, y2})
        end

        love.graphics.setBlendMode('alpha')

        for i=1,this.num_dirt_particles do
            local v = this.dirt_particles[i]

            love.graphics.push()
            love.graphics.setColor({v.alpha / 3.5, v.alpha / 3.5, v.alpha / 3.5, v.alpha})
            love.graphics.translate(v.x, v.y)
            love.graphics.rotate(v.ang)
            love.graphics.rectangle('fill', - v.size / 2, - v.size / 2, v.size, v.size)
            love.graphics.pop()
        end
    end,
}
