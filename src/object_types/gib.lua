--- Gib object type.

local map            = require 'map'
local object         = require 'object'
local physics_groups = require 'physics_groups'
local sprite         = require 'sprite'

return {
        defaults = function()
		return {
			x = 0, -- location and velocity are included in defaults because they are REQUIRED to be present.
			y = 0,
			dx = 0,
			dy = 0,
			wait = 5, -- time to wait before destroying in seconds
			color = {1, 1, 1, 1}, -- render color
			flip = false, -- horizontal render flip
		}
	end,

	init = function(this)
		this.spr = sprite.create(this.spr_name)
		this.w, this.h = sprite.frame_size(this.spr)

		this.shape = love.physics.newRectangleShape(this.w, this.h)
		this.body = love.physics.newBody(map.get_physics_world(), this.x + this.w / 2, this.y + this.h / 2, 'dynamic')
		this.fixture = love.physics.newFixture(this.body, this.shape)

		this.fixture:setCategory(physics_groups.GIB)
		this.fixture:setMask(physics_groups.GIB)
		this.fixture:setRestitution(0.1)

		this.body:setLinearVelocity(this.dx, this.dy)
		this.body:applyAngularImpulse(math.random(-10, 10))
		this.body:setAngle(this.angle or 0)
	end,

	destroy = function(this)
		this.body:destroy()
	end,

	update = function(this, dt)
		this.wait = this.wait - dt

		if this.wait < 0 then
			this.color[4] = this.color[4] - dt

			if this.color[4] < 0 then
				object.destroy(this)
			end
		end
	end,

	render = function(this)
		this.angle = this.body:getAngle()

		this.x = this.body:getX() - this.w / 2
		this.y = this.body:getY() - this.h / 2

		love.graphics.setColor(this.color)
		sprite.render(this.spr, this.x, this.y, this.angle, this.flip)
	end,
}
