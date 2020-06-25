--- Explosion effect.
-- Renders all visual elements of an explosion and then dissappears.

local object = require 'object'

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

        this.smoke_particles = {}
        for i=1,this.num_smoke_particles do
            local ang = math.random() * 2.0 * 3.141
            local rad = math.random() * this.smoke_radius_max

            this.smoke_particles[i] = {
                rotspeed = math.random() * (this.smoke_rotation_max - this.smoke_rotation_min) + this.smoke_rotation_min,
                alpha_decay = math.random() * (this.smoke_alpha_decay_max - this.smoke_alpha_decay_min) + this.smoke_alpha_decay_min,
                x = this.x + math.cos(ang) * rad,
                y = this.y + math.sin(ang) * rad,
                ang = math.random() * 2.0 * 3.141,
                alpha = math.random() * (this.smoke_alpha_max - this.smoke_alpha_min) + this.smoke_alpha_min,
                dx = math.random() * (this.smoke_dx_max - this.smoke_dx_min) + this.smoke_dx_min,
                dy = math.random() * (this.smoke_dy_max - this.smoke_dy_min) + this.smoke_dy_min,
                size = math.random() * (this.smoke_size_max - this.smoke_size_min) + this.smoke_size_min,
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
    end,
}
