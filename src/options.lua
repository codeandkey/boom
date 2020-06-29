--- Options control.

local util  = require 'util'
local log   = require 'log'
local event = require 'event'

local options = {
    PATH = 'options.lua',
}

--- Tries to import options from the disk.
-- If no options are saved, tries to find sane defaults.
-- @return true if a valid mode was loaded, false otherwise
function options.load()
    local status, result = util.execfile(options.PATH)

    if status then
        options.values = result

        if love.window.setMode(result.width, result.height, result.flags) then
            log.info('Applied saved mode: %s', options.modestring())
            event.push('fbsize', options.values.width, options.values.height)

            return true
        else
            log.warn('Failed to apply saved mode, trying defaults..')
            return options.defaults()
        end
    else
        log.info('Failed to read saved mode, applying defaults..')

        if not options.defaults() then
            return false
        end

        return options.write()
    end
end

function options.defaults()
        options.values = {
            flags = {
                fullscreen = true,
                vsync = 1,
                msaa = 0,
            },
        }

        local res = love.window.setMode(0, 0, options.values.flags)

        options.values = {
            flags = options.values.flags,
            width = love.graphics.getWidth(),
            height = love.graphics.getHeight(),
        }

        if res then
            log.info('Applied default mode: %s', options.modestring())
            event.push('fbsize', options.values.width, options.values.height)

            return true
        else
            log.warn('Failed to apply default mode: %s', options.modestring())
            return false
        end
end

function options.modestring()
    return string.format('%d by %d, fullscreen %s, vsync %s, msaa %d',
        options.values.width,
        options.values.height,
        tostring(options.values.flags.fullscreen), 
        options.values.flags.vsync,
        options.values.flags.msaa
    )
end

function options.write()
    return util.serialize_to_file(options.values, options.PATH)
end

return options
