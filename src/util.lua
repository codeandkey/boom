--- Functions for maths, collisions, and other misc helpers.

local log = require 'log'
local util = {}

--- Perform an AABB collision test
-- Each rectangle should have the numeric fields 'x', 'y', 'w', and 'h'.
-- @param a First rectangle
-- @param b Second rectangle
-- @return true if _a_ intersects _b_
function util.aabb(a, b)
    if a.x + a.w <= b.x then return false end
    if b.x + b.w <= a.x then return false end
    if a.y + a.h <= b.y then return false end
    if b.y + b.h <= a.y then return false end

    return true
end

--- Get path basename
-- Equivalent of the POSIX basename(), grabbing the last path element.
-- @param str Path to basename
-- @return Basename of _str_
function util.basename(str)
    return string.gsub(str, "(.*/)(.*)", "%2")
end

--- Pack variable arguments
-- Part of standard lua, but seems to be missing from LOVE.
-- See lua's "table.pack" for reference.
function util.pack(...)
    return { n = select('#', ...), ... }
end

--- @{pcall} wrapper which logs errors.
-- See @{pcall} for reference.
-- @param func Function to call.
-- @param ... Arguments to pass.
function util.pcall(func, ...)
    if func == nil then
        return true -- Don't consider nil calls errors.
    end

    local status, result = pcall(func, ...)

    if not status then
        log.warn('pcall() failed: %s', result)
    end

    return status, result
end

--- Returns a random flaot in a range.
-- @param min Minimum value.
-- @param max Maximum value.
-- @return Random float between min and max.
function util.randrange(min, max)
    return math.random() * (max - min) + min
end

--- Tries to execute a file and return the result.
-- @param path Path of file to execute, relative to top-level directory.
-- @return status, result
function util.execfile(path)
    return util.pcall(function() return dofile(path) end)
end

--- Serializes a table object into a string.
-- @param input Input table. Should only contain strings, numbers, or tables.
-- @return Serialized string output.
function util.serialize(v)    
    if type(v) == 'table' then    
        local out = '{ '    
        for k, nv in pairs(v) do    
            out = out .. '["' .. k .. '"] = ' .. util.serialize(nv) .. ','    
        end    
        return out .. ' }'    
    elseif type(v) == 'string' then    
        return '"' .. v .. '"'    
    elseif type(v) == 'number' or type(v) == 'boolean' then    
        return tostring(v)    
    end    
end

--- Serializes a table object into a lua file.
-- @param input Input table. Should only contain strings, numbers, or tables.
-- @param path Output file path
-- @return true if successful, false otherwise
function util.serialize_to_file(v, path)
    local status, ofile = pcall(io.open, path, 'w')

    if not status then
        log.error("Failed to write to %s: %s", path, ofile)
        return false
    end

    ofile:write('return ' .. util.serialize(v))
    ofile:close()

    return true
end

return util
