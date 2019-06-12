--[[
    options.lua

    game options interface
--]]

local options = {
    default_path = 'assets/options',
    loaded_path = nil,

    -- default values
    values = {
        fullscreen = false,
    },
}

function options.import(path)
    -- use default path if not provided
    if path == nil then
        path = options.default_path
    end

    -- load values from disk
    local import_values = require(path)
    local count = 0
    options.loaded_path = path

    -- merge imported options into current state
    for k, v in pairs(import_values) do
        options.values[k] = v
        count = count + 1
    end

    print('imported ' .. count .. ' options from ' .. path .. '.lua')
end

function options.export(path)
    -- export to current option file if not provided
    if path == nil then
        path = options.loaded_path
    end

    -- overwrite the option path
    local ofile = assert(io.open('src/' .. path .. '.lua', 'w'))

    -- write the header with some info
    ofile:write('--[[\n')
    ofile:write('    boom options file "' .. path .. '"\n')
    ofile:write(os.date('    generated on %d %B %Y at %H:%M:%S\n'))

    -- warn tempted users
    ofile:write('    Please use the in-game option menu to change these values!\n')
    ofile:write(']]--\n\n')
    ofile:write('return {\n')

    local count = 0
    
    -- write option values
    for k, v in pairs(options.values) do
        if type(v) == 'string' then
            ofile:write('    ' .. k .. ' = "' .. v .. '",\n')
        elseif type(v) == 'boolean' or type(v) == 'number' then
            ofile:write('    ' .. k .. ' = ' .. tostring(v) .. ',\n')
        else
            print('weird option value! key=' .. k .. ', type=' .. type(v))
        end

        count = count + 1
    end

    -- finish up value block
    ofile:write('}\n')
    ofile:close()

    -- all done!
    print('exported ' .. count .. ' options to src/' .. path .. '.lua')
end

function options.apply_all()
    -- go through each value and apply them

    -- fullscreen option
    options.set_fullscreen(options.values.fullscreen)
end

function options.set_fullscreen(val)
    -- if no value provided, just invert the current status
    if val == nil then
        val = not options.values.fullscreen
    end

    options.values.fullscreen = val
    love.window.setFullscreen(val)
end

return options
