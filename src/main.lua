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
    love.graphics.clear(0.15, 0.15, 0.15, 0)

    camera.apply()
    map.render()

    if love.keyboard.isDown('p') then
        map.render_phys_debug()
    end

    camera.unapply()
end
