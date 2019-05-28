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
    return require('maps/' .. name)
end

--[[
    rendering functions
--]]

function map.render(map_data)
    for y=1,map_data.height do
        for x=1,map_data.width do
            local tile_id = map_data.data[x + (y-1) * map_data.width]

            if tile_id ~= 0 then
                love.graphics.setColor(map.tiles[tile_id].color)
                love.graphics.rectangle('fill', x * tile_width, y * tile_height, tile_width, tile_height)
            end
        end
    end
end

return map
