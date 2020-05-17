--- Game string table manager.

local log = require 'log'

local strings = {
	vals = {},
}

--- Load a language into the string table.
-- @param lang Language to load, from strings/<name>.lua
function strings.load(lang)
	local status, result = pcall(function() return require ('strings/' .. lang) end)

	if status then
		strings.vals = result
	else
		log.error('Error loading strings for language ' .. lang .. '!')
	end
end

--- Get a game string.
-- @param name String index to retrieve.
-- @return The associated string, or '[ERROR]' if not found.
function strings.get(index)
	return strings.vals[index] or '[ERROR]'
end

strings.load('english')
return strings
