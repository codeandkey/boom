--[[
    main.lua
    entry point
--]]

local map = require 'map'
local world

function love:load()
    world = map.load('test')
end

function love:draw()
    map.render(world)
end
