--- Options subsystem.
-- This subsystem manages the application and persistence of in-game options.

local log = require 'log'

local default_opts = {
    fullscreen = true,
    fullscreen_type = 'desktop',
    msaa = 0,
    vsync = false,
}

local opts = {
    values = {},
    path = 'assets/opts',
}

--- Merges option values from a table.
-- Does not apply the options.
-- @param tbl Table of options to set.
function opts.load_table(tbl)
    for k, v in pairs(tbl) do
        opts.values[k] = v
    end
end

--- Import options from the disk.
-- Does not apply the options.
function opts.load()
    status, result = pcall(function() return require(opts.path) end)

    if status then
        opts.load_table(result)
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
    ofile:write('return {\n')

    -- Write non-default keys.
    for k, v in pairs(opts.values) do
        if v ~= default_opts[k] then
            -- Non-default. Export me!
            log.debug('Exporting non-default option key %s', k)

            if type(v) == 'string' then
                ofile:write('    %s = "%s"\n', k, v)
            elseif type(v) == 'number' or type(v) == 'boolean' then
                ofile:write('    %s = %s\n', k, tostring(v))
            else
                log.error('Ignoring invalid value type %s for key %s!', type(v), k)
            end
        end
    end

    ofile:write('}\n')
    ofile:close()

    log.info('Wrote options to %s', 'src/' .. opts.path .. '.lua')
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

-- Set default options initially.
opts.load_table(default_opts)

return opts
