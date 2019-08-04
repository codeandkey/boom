--[[
    main.lua
    entry point and mainloop
]]--

local camera = require 'camera'
local event  = require 'event'
local input  = require 'input'
local log    = require 'log'
local map    = require 'map'

function love.load()
    love.window.setFullscreen(true)
    love.graphics.setDefaultFilter('nearest', 'nearest')

    map.load('main_menu')
    log.info('Finished loading.')
end

function love.resize(w, h)
    log.debug('Display resized to %d by %d', w, h)
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
