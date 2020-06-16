--- Background object type.

local camera = require 'camera'
local log    = require 'log'
local object = require 'object'
local sprite = require 'sprite'

return {
	defaults = function()
		return {
			parallax_x = 1,                                 -- parallax horizontal factor
			parallax_y = 1,                                 -- parallax vertical factor
			image      = '800x600_background_sky_blue.png', -- background sprite path
			frame_w    = 800,                               -- background sprite frame width
			frame_h    = 600,                               -- background sprite frame height
			duration   = 1,                                 -- background sprite frame duration
		}
	end,

	init = function(this)
		this.spr = sprite.create('bg/' .. this.image, this.frame_w, this.frame_h, this.duration)
		this.spr_w, this.spr_h = sprite.frame_size(this.spr)
	end,

	update = function(this, dt)
		if this.spr then
			sprite.update(this.spr, dt)
		end
	end,

	render = function(this)
		if not this.spr then
			log.error('Background object missing sprite! Name: %s', this.name)
			object.destroy(this)
			return
		end

		-- Get the camera center.
		local cx, cy = camera.get_center()

		-- Grab the camera bounds too.
		local bounds = camera.get_bounds()

		-- Offset by parallax factors.
		cx = cx / this.parallax_x
		cy = cy / this.parallax_y

		love.graphics.setColor(1, 1, 1, 1)

		if this.offset_x then
			cx = cx + this.offset_x
		end

		if this.offset_y then
			cy = cy + this.offset_y
		end

		if this.repeat_x then
			-- Move the parallax point until it is within the camera bounds.
			-- Then render the background once to the left and once to the right.
			while cx < bounds.x do
				cx = cx + this.spr_w
			end

			while cx > bounds.x + bounds.w do
				cx = cx - this.spr_w
			end

			sprite.render(this.spr, cx - this.spr_w / 2, cy - this.spr_h / 2)
			sprite.render(this.spr, cx - 3 * this.spr_w / 2, cy - this.spr_h / 2)
			sprite.render(this.spr, cx + this.spr_w / 2, cy - this.spr_h / 2)
		else
			-- Render the sprite, centered on the camera (+ parallax)
			sprite.render(this.spr, cx - this.spr_w / 2, cy - this.spr_h / 2)
		end
	end
}
