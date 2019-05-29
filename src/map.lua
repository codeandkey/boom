--[[
    map.lua
    functions for loading/managing tile-based maps

    as a PLACEHOLDER a map is a table with the following fields:
        width   : map width (in tiles)
        height  : map height (in tiles)
        data    : array of tile IDs (row-major, single dimension, first tile at top-left corner)
        start_x : player initial x
        start_y : player initial y
--]]

local obj = require 'obj'
local map = { tiles = {} }

--[[
    constants
--]]

local tile_width  = 16
local tile_height = 16

--[[
    tile type definitions
--]]

map.tiles[0] = nil -- air/empty

-- some basic colored tiles

map.tiles[1] = { color={ 1, 1, 1, 1 } }
map.tiles[2] = { color={ 1, 0, 0, 1 } }
map.tiles[3] = { color={ 0, 1, 0, 1 } }
map.tiles[4] = { color={ 0, 0, 1, 1 } }

--[[
    loader functions
--]]

function map.load(name)
    -- placeholder map loader
    map.current = require('maps/' .. name)

    for k, v in pairs(map.current.objects) do
        obj.create(v.typename, v.initial)
    end
end

--[[
    rendering functions
--]]

function map.render()
    for y=1,map.current.height do
        for x=1,map.current.width do
            local tile_id = map.current.data[x + (y-1) * map.current.width]

            if tile_id ~= 0 then
                love.graphics.setColor(map.tiles[tile_id].color)
                love.graphics.rectangle('fill', (x - 1) * tile_width, (y - 1) * tile_height, tile_width, tile_height)
            end
        end
    end
end

--[[
    collision testing
--]]

function map.collide_aabb(box)
    -- collide points along each edge of the bounding box

    --[[
        TODO: this should be replaced with a more efficient algorithm using actual aabb testing
        during the map load tiles should be merged together into large collision boxes, so we can
        test collisions against those instead of individual tiles like this.

        horizontal blocks are a good optimization to start with, vertical merging is more difficult
    --]]

    for x=box.x,(box.x+box.w) do
        if map.collide_point({ x=x, y=box.y+box.h }) then return true end
        if map.collide_point({ x=x, y=box.y }) then return true end
    end

    for y=box.y,(box.y+box.h) do
        if map.collide_point({ x=box.x, y=y }) then return true end
        if map.collide_point({ x=box.x+box.w, y=y }) then return true end
    end
end

function map.collide_point(p)
    -- we need to convert real coordinates to tile coordinates
    return map.current.data[1 + math.floor(p.x / tile_width) + map.current.width * math.floor(p.y / tile_height)] ~= 0
end

return map
