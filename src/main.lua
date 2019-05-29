--[[
    main.lua
    entry point
--]]

local map = require 'map'
local obj = require 'obj'

function love.load()
    map.load('test')
end

function love.update(dt)
    obj.update_all(dt)
end

function love.draw()
    map.render()
    obj.render_all()
end
