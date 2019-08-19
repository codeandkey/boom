--- Options subsystem.
-- This subsystem manages the application and persistence of in-game options.

local log = require 'log'

local opts = {
    values = {},
    path = 'assets/opts',
}

--- Set an option, but do not save it.
-- @param key Option index.
-- @param val Value to assign.
function opts.set(key, val)
    opts.values[key] = val
end

--- Get an option value.
-- @param key Option index.
function opts.get(key)
    return opts.values[key]
end

--- Import option values from the disk.
function opts.load()
    local status, result = pcall(function() return require(opts.path) end)

    if status then
        for k, v in pairs(result) do
            opts.values[k] = v
        end

        log.info('Loaded options from src/%s.lua', opts.path)
    else
        log.error("Couldn't import options from src/%s.lua!", opts.path)
    end
end

--- Exports non-default options to the disk.
function opts.save()
    local status, ofile = pcall(io.open, 'src/' .. opts.path .. '.lua', 'w')

    if not status then
        return log.error("Failed to save options to %s.lua: %s", opts.path, ofile)
    end

    ofile:write('-- Boom options file. Do not edit while game is running!\n')
    ofile:write('-- Your changes may be lost.\n\n')
    ofile:write('return ' .. opts.serialize(opts.values))
    ofile:close()

    log.info('Wrote state to %s', 'src/' .. opts.path .. '.lua')
end

--- Serialize a Lua value for writing configs.
-- @param Value to serialize.
-- @return String with serialized data.
function opts.serialize(v)
    if type(v) == 'table' then
        local out = '{ '
        for k, nv in pairs(v) do
            out = out .. '["' .. k .. '"] = ' .. opts.serialize(nv) .. ','
        end
        return out .. ' }'
    elseif type(v) == 'string' then
        return '"' .. v .. '"'
    elseif type(v) == 'number' or type(v) == 'boolean' then
        return tostring(v)
    end
end

opts.load()
return opts
