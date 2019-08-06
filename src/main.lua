--[[
    main.lua
    entry point and mainloop
]]--

local camera = require 'camera'
local event  = require 'event'
local input  = require 'input'
local log    = require 'log'
local map    = require 'map'
local opts   = require 'opts'

function love.load()
    -- Load game. Check first: is there a saved mode? If so, apply it.
    local mode = opts.get('mode')

    if mode then
        log.debug('Applying saved video mode..')
        love.window.setMode(mode.width, mode.height, mode.flags)
    else
        -- Choose the nicest looking default mode.
        love.window.setFullscreen(true)
    end


    -- Send a resize event to set up anything dependent on fb size.
    local w, h, _ = love.window.getMode()
    log.debug('Pushing fbsize event: %d, %d', w, h)
    event.push('fbsize', w, h)

    love.graphics.setDefaultFilter('nearest', 'nearest')

    map.load('main_menu')
    log.info('Finished loading.')
end

function love.resize()
    local w, h, flags = love.window.getMode()

    log.debug('Using new video mode: %d by %d, fullscreen %s (%s), vsync %s, msaa %s',
              w, h, flags.fullscreen, flags.fullscreentype, tostring(flags.vsync), flags.msaa)

    camera.rescale(w)
end

function love.keypressed(key)
    -- Translate key to the bound input (if there is one).
    local inp = input.translate(key)

    if inp ~= nil then
        event.push('inputdown', inp)
    end
end

function love.keyreleased(key)
    local inp = input.translate(key)

    if inp ~= nil then
        event.push('inputup', inp)
    end
end

function love.quit()
    map.unload()
end

function love.update(dt)
    -- Process all pending game events.
    event.run()

    map.update(dt)
    camera.update(dt)
end

function love.draw()
    -- Render the current map with the camera applied.
    camera.apply()
    map.render()
    camera.unapply()
end
