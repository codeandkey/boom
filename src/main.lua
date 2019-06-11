--[[
    main.lua
    entry point
--]]

local map = require 'map'

function love.load()
    -- initial graphics setup

    -- use nearest filtering over "blurry" linear filtering
    love.graphics.setDefaultFilter('linear', 'nearest')

    map.load('test')
end

function love.update(dt)
    map.update(dt)
end

function love.draw()
    map.render()
end
