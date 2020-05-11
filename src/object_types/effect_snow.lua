--- Snow particle effect.

local camera = require 'camera'
local fs     = require 'fs'

return {
    init = function(this)
        -- Configuration.
        this.num_particles = this.num_particles or 300
        this.dx_min        = this.dx_min or -20
        this.dx_max        = this.dx_max or 20
        this.dy_min        = this.dy_min or 5
        this.dy_max        = this.dy_max or 10
        this.dr_min        = this.dr_min or -1
        this.dr_max        = this.dr_max or 1
        this.color         = this.color or {1, 1, 1, 1}
        this.wrap_padding  = this.wrap_padding or 32

        -- Load snowflake sheet.
        this.snowflake_sheet = fs.read_texture('32x32_snowflake_sheet.png')

        -- Snowflake sprite quads.
        this.snowflake_quads = {
            {
                q = love.graphics.newQuad(0, 0, 3, 3, 32, 32),
                ox = 1.5, oy = 1.5,
            },
            {
                q = love.graphics.newQuad(4, 0, 4, 4, 32, 32),
                ox = 2,
                oy = 2,
            },
            {
                q = love.graphics.newQuad(9, 0, 5, 5, 32, 32),
                ox = 2.5,
                oy = 2.5,
            },
            {
                q = love.graphics.newQuad(0, 5, 5, 5, 32, 32),
                ox = 2.5,
                oy = 2.5,
            },
        }

        local random_quad = function()
            return this.snowflake_quads[math.random(#this.snowflake_quads)]
        end

        local random_range = function(min, max)
            return math.random() * (max - min) + min
        end

        -- Locate camera bounds.
        this.bounds = camera.get_bounds()

        -- Construct batch for rendering.
        this.batch = love.graphics.newSpriteBatch(this.snowflake_sheet)

        -- State.
        this.particles = {}

        for i=1,this.num_particles do
            local quad = random_quad()

            this.particles[i] = {
                quad = quad,
                dx   = random_range(this.dx_min, this.dx_max),
                dy   = random_range(this.dy_min, this.dy_max),
                dr   = random_range(this.dr_min, this.dr_max),
                x    = random_range(this.bounds.x, this.bounds.x + this.bounds.w),
                y    = random_range(this.bounds.y, this.bounds.y + this.bounds.h),
                r    = random_range(0, 3.141 * 2.0),
                a    = math.random(),
                ind  = this.batch:add(quad.q, 0, 0),
            }
        end
    end,

    update = function(this, dt)
        this.bounds = camera.get_bounds()

        -- Update particle states.
        for _, v in ipairs(this.particles) do
            v.x = v.x + dt * v.dx
            v.y = v.y + dt * v.dy
            v.r = v.r + dt * v.dr

            -- Horizontal wrap.
            if v.x > this.bounds.x + this.bounds.w + this.wrap_padding then
                v.x = this.bounds.x - this.wrap_padding
            elseif v.x < this.bounds.x - this.wrap_padding then
                v.x = this.bounds.x + this.bounds.w + this.wrap_padding
            end

            -- Vertical wrap.
            if v.y > this.bounds.y + this.bounds.h + this.wrap_padding then
                v.y = this.bounds.y - this.wrap_padding
                v.x = math.random() * this.bounds.w + this.bounds.x
            end

            if v.y < this.bounds.y - this.wrap_padding then
                v.y = this.bounds.y + this.bounds.h + this.wrap_padding
                v.x = math.random() * this.bounds.w + this.bounds.x
            end

            this.batch:setColor(1, 1, 1, v.a)

            -- Update batch for rendering.
            this.batch:set(v.ind, v.quad.q, v.x, v.y, v.r, 1, 1, v.quad.ox, v.quad.oy)
        end
    end,

    render = function(this)
        -- Use batch to render all snowflakes at once.
        love.graphics.draw(this.batch)
    end,
}
