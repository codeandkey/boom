--[[
    main.lua
    entry point
--]]

local camera = require 'camera'
local map = require 'map'
local options = require 'options'

function love.load()
    -- load options
    options.import()
    options.apply_all()

    -- use nearest filtering over "blurry" linear filtering
    love.graphics.setDefaultFilter('linear', 'nearest')

    map.load('test')
end

function love.keypressed(key)
    if key == 'f4' then
        options.set_fullscreen()
        options.export()
    end
end

function love.update(dt)
    map.update(dt)
end

function love.draw()
    camera.apply()
    map.render()
    camera.unapply()
end
