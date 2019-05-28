--[[
    main.lua
    entry point
--]]

local map = require 'map'
local obj = require 'obj'

local world
local player

function love.load()
    world = map.load('test')
    player = obj.create('player', world.start_x, world.start_y)
end

function love.update(dt)
    obj.update(player, dt)
end

function love.draw()
    map.render(world)
    obj.render(player)
end
