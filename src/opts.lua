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
    status, result = pcall(function() return require(opts.path) end)

    if status then
        for k, v in pairs(result) do
            opts.values[k] = v
        end

        log.info('Loaded options from src/%s.lua', opts.path)
    else
        log.error("Couldn't import options from src/%s.lua: %s", opts.path, result)
    end
end

--- Exports non-default options to the disk.
function opts.save()
    status, ofile = pcall(io.open, 'src/' .. opts.path .. '.lua', 'w')

    if not status then
        return log.error("Failed to save options to %s.lua: %s", opts.path, ofile)
    end

    ofile:write('-- Boom options file. Do not edit while game is running!\n')
    ofile:write('-- Your changes may be lost.\n\n')
    ofile:write('return ' .. opts.serialize(opts.values))
    ofile:close()

    log.info('Wrote options to %s', 'src/' .. opts.path .. '.lua')
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

--- Applies game options.
function opts.apply()
    -- First, construct and set the video mode.
    -- If no resolution is specified the monitor size is used.
    
    -- Construct the mode.
    local new_mode = {
        fullscreen = opts.values.fullscreen,
        fullscreentype = opts.values.fullscreen_type,
        msaa = opts.values.msaa,
        vsync = opts.values.vsync,
    }

    -- Try and apply it.
    result = love.window.setMode(opts.values.width or 0,
                                 opts.values.height or 0,
                                 new_mode)

    if result then
        local ww, wh = love.graphics.getDimensions()

        log.info('Applied game video mode.')
        log.info('%d by %d, fullscreen %s, vsync %s, msaa %d', ww, wh, tostring(opts.values.fullscreen), tostring(opts.values.vsync), opts.values.msaa)
        log.info('Fullscreen method is %s', opts.values.fullscreen_type)
    else
        log.error('Error applying video mode!')
    end
end

--- Sets game fullscreen state and option.
-- Does not write options to disk or apply.
-- If _set_ is a boolean then the fullscreen option is changed to _set_.
-- Otherwise, the option is toggled.
-- @param set Optional boolean value.
function opts.set_fullscreen(set)
    opts.values.fullscreen = set or not opts.values.fullscreen
end

opts.load()
return opts
