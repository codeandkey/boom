--[[
    main.lua
    entry point
--]]

local camera = require 'camera'
local map = require 'map'

function love.load()
    map.load('test')
end

function love.update(dt)
    map.update(dt)
end

function love.draw()
    camera.apply()
    map.render()
    camera.unapply()
end
