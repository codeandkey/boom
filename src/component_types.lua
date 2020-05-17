--- Collection of object components.

local log = require 'log'
local component_types = {}

setmetatable(component_types, {
	__index = function(_, index)
		local status, type_table = pcall(function() return require('component_types/' .. index) end)

		if not status then
			log.error('Unknown component type %s! (%s)', index, type_table)
		else
			return type_table
		end
	end,
})

return component_types
