--[[
    main.lua
    entry point
--]]

local map = require 'map'

function love.load()
    map.load('test')
end

function love.update(dt)
    map.update(dt)
end

function love.draw()
    map.render()
end
