--- Explosion effect.
-- Renders all visual elements of an explosion and then dissappears.

local object = require 'object'
local util = require 'util'
local map = require 'map'

return {
    init = function(this)
        this.num_smoke_particles = this.num_smoke_particles or math.random(32, 80)

        this.smoke_alpha_decay_min = 1.5
        this.smoke_alpha_decay_max = 3
        this.smoke_alpha_min = 0.5
        this.smoke_alpha_max = 1
        this.smoke_rotation_min = -1
        this.smoke_rotation_max = 1
        this.smoke_dx_min = -100
        this.smoke_dx_max = 100
        this.smoke_dy_min = -125
        this.smoke_dy_max = -65
        this.smoke_size_min = 4
        this.smoke_size_max = 9
        this.smoke_radius_max = 32

        this.num_shrap_particles = this.num_shrap_particles or math.random(32, 64)

        this.shrap_alpha_decay_min = 2
        this.shrap_alpha_decay_max = 4
        this.shrap_alpha_min = 0.5
        this.shrap_alpha_max = 1
        this.shrap_speed_min = 400
        this.shrap_speed_max = 800
        this.shrap_size_min = 8
        this.shrap_size_max = 24
        this.shrap_width_min = 0.2
        this.shrap_width_max = 1
        this.shrap_radius_max = 32

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

            if map.aabb_tile({
                x = x2,
                y = y2,
                w = 1,
                h = 1,
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

        if not live then
            object.destroy(this)
        end
    end,

    render = function(this)
        for i=1,this.num_smoke_particles do
            local v = this.smoke_particles[i]

            love.graphics.push()
            love.graphics.setColor({1, 1, 1, v.alpha})
            love.graphics.translate(v.x + v.size / 2, v.y + v.size / 2)
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
    end,
}
