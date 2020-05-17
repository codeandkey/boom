--- NPC object type.
local object = require 'object'

-- Type-wide constants can go here
local npc = {
	Tom = {
		color = {1, 0, 1, 1},
	},
	Fred = {
		color = {0, 1, 1, 1},
	},
	Joe = {
		color = {0.5, 1, 1, 1},
	},
	Bill = {
		color = {0.5, 1, 0.5, 1},
	},
	noname = {
		color = {1, 1, 1, 1}
	},
}

return {
	init = function(this)
		-- Which NPC are we?
		this.name = this.name or 'noname'
		this.mode = npc[this.name]

		-- Static movement properties
		this.dx_max =50

		-- Random movement state.
		this.thought_timer_variation = 5
		this.thought_timer_min       = 3
		this.thought_timer           = 0

		-- Set the sprites to be used
		this.spriteset = 'char/hero/'

		-- Create a character component, but don't subsbcribe to input events.
		-- We will generate our own.
		object.add_component(this, 'character', {
			x = this.x,
			y = this.y,
			dx_max = this.dx_max,
			spriteset = this.spriteset
		})
	end,

	update = function(this, dt)
		local char = this.components.character

		this.thought_timer = this.thought_timer - dt

		if this.thought_timer < 0 then
			-- Perform a new thought.

			if math.random(0, 1) == 0 then
				-- Move somewhere. What direction?
				if math.random(0, 1) == 0 then
					-- Go left!
					object.call(char, 'inputdown', 'left')
					object.call(char, 'inputup', 'right')
				else
					-- Go other left!
					object.call(char, 'inputdown', 'right')
					object.call(char, 'inputup', 'left')
				end
			else
				-- Stop moving and wait. Release all keys.
				object.call(char, 'inputup', 'left')
				object.call(char, 'inputup', 'right')
			end

			-- Wait a semirandom time before thinking again.
			this.thought_timer = math.random(0, this.thought_timer_variation) + this.thought_timer_min
		end

		-- Check if we've run into a wall.
		if char.is_walking and math.abs(char.dx) < 10 then
			-- Will we try and vault it?
			if math.random(0, 2) > 0 then
				-- Send a jump keypress!
				object.call(char, 'inputdown', 'jump')

				-- Normally we'd send an 'inputup' to release the jump, but the
				-- character component doesn't actually listen for it.
			else
				-- Give up and stop walking.
				object.call(char, 'inputup', 'left')
				object.call(char, 'inputup', 'right')
			end
		end

		-- Kill the object if the character dies.
		if char.dead then
			object.destroy(this)
		end

		-- Mark our object position (for collision calculation)
		this.x = char.x + char.w / 2
		this.y = char.y + char.h / 2
	end
}
