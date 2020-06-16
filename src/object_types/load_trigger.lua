--- Load Trigger object type.
-- Transitions game between maps when the player interacts with it.

local log = require 'log'
local map = require 'map'

return {
	defaults = function()
		return {
			destination = 'main_menu',
			interactable = 'false',
		}
	end,

	interact = function(this, caller)
		if caller.__typename == 'player' then
			map.request(this.destination, this.entry_point)
		else
			log.debug('ignoring interact from object type %s', caller.__typename)
		end
	end,
}
