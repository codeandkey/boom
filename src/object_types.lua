--- Collection of object types.

local log = require 'log'
local object_types = {}

setmetatable(object_types, {
    __index = function(table, index)
        status, type_table = pcall(function() return require('object_types/' .. index) end)

        if not status then
            log.error('Unknown object type %s!', index)
        else
            return type_table
        end
    end,
})

return object_types
