--- Nade object type.

local map          = require 'map'
local object       = require 'object'
local object_group = require 'object_group'
local shaders      = require 'shaders'
local sprite       = require 'sprite'

return {
    init = function(this)
        -- Configuration.
        this.radius = this.radius or 8
        this.spin = this.spin or math.random(-100, 100)

        this.flash_params = this.flash_params or {
            { color={ 1, 0.2, 0, 1 }, pct=0.0, delay=0.07 },  -- red
            { color={ 1, 0.7, 0, 1 }, pct=0.25, delay=0.15 }, -- yellow
            { color={ 1, 1, 1, 1 }, pct=0.5, delay=0.3 },   -- white
        }

        -- Resources.
        this.spr = sprite.create('16x16_nade.png')

        -- State.
        this.thrown = false
        this.angle = 0
        this.fuse_time = this.fuse_time or 2.5
        this.init_fuse_time = this.init_fuse_time or this.fuse_time
        this.flash_timer = 0
        this.flash_color = {1, 1, 1, 1}

        -- Member funcs.
        this.throw = function(self, dx, dy)
            self.shape = love.physics.newCircleShape(self.radius)
            self.body = love.physics.newBody(map.get_physics_world(), self.x, self.y, 'dynamic')
            self.fixture = love.physics.newFixture(self.body, self.shape, 1)
            self.body:applyLinearImpulse(dx, dy)
            self.body:applyAngularImpulse(self.spin)
            self.thrown = true
        end
    end,

    destroy = function(this)
        -- Create an explosion. Place it in the same layer as this.
        object_group.create_object(this.__layer, 'explosion', { x = this.x, y = this.y })

        if this.thrown then
            this.body:destroy()
        end
    end,

    update = function(this, dt)
        -- Follow physics body if thrown.
        if this.thrown then
            this.x, this.y = this.body:getPosition()
            this.angle = this.body:getAngle()
        end

        -- Unconditionally update fuse timer.
        if this.fuse_time > 0 then
            this.fuse_time = this.fuse_time - dt
        else
            object.destroy(this)
        end

        -- Update flash phase.
        if this.flash_timer < 0 then
            this.in_flash = not this.in_flash

            local pct = this.fuse_time / this.init_fuse_time
            for _, phase in ipairs(this.flash_params) do
                if pct > phase.pct then
                    this.flash_timer = phase.delay
                    this.flash_color = phase.color
                end
            end
        else
            this.flash_timer = this.flash_timer - dt
        end
    end,

    render = function(this)
        -- Switch shader and color if flashing.
        if this.in_flash then
            love.graphics.setColor(this.flash_color)
            love.graphics.setShader(shaders.flash)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end

        sprite.render(this.spr, this.x - this.radius, this.y - this.radius, this.angle)

        -- Restore normal shader.
        love.graphics.setShader()
    end,
}
