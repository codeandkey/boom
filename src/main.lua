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
    player = obj.create('player', { x=world.start_x, y=world.start_y })
end

function love.update(dt)
    obj.update_all(dt)
end

function love.draw()
    map.render(world)
    obj.render_all()
end
