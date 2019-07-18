--[[
    main.lua
    entry point and mainloop
]]--

local event = require 'event'
local input = require 'input'
local log = require 'log'
local map = require 'map'

function love.load()
    map.load('test')
    log.info('Finished loading.')
end

function love.keypressed(key)
    log.debug('In main handler for keypressed: %s', key)

    -- Translate key to the bound input (if there is one).
    local inp = input.translate(key)

    log.debug('Translated to %s', inp)

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
end

function love.draw()
    map.render()
end
