--[[
    map.lua
    functions for loading/managing tile-based maps
--]]

local obj = require 'obj'
local util = require 'util'
local map = {}

--[[
    loader functions
--]]

function map.load(name)
    map.current = require('assets/maps/' .. name)
    map.current.tiles = {}

    -- for now, only allow one tileset
    -- this is because batches can only go through one image and dividing
    -- that will be very painful when loading
    assert(#map.current.tilesets <= 1)

    -- initialize tilesets
    for k, v in ipairs(map.current.tilesets) do
        v.texture = love.graphics.newImage('assets/sprites/' .. util.basename(v.image))

        -- create quads for each tile in the set
        local cur_tile = v.firstgid
        local tw, th = v.tilewidth, v.tileheight
        
        for y=0,(v.imageheight/v.tileheight)-1 do
            for x=0,(v.imagewidth/v.tilewidth)-1 do
                map.current.tiles[cur_tile] = love.graphics.newQuad(x * tw, y * th, tw, th, v.imagewidth, v.imageheight)
            end

            cur_tile = cur_tile + 1
        end
    end

    -- initialize layers
    for k, v in ipairs(map.current.layers) do
        if v.type == 'tilelayer' then
            -- create render batch alongside data
            v.batch = love.graphics.newSpriteBatch(map.current.tilesets[1].texture, 1000, 'static')

            for y=0,v.height-1 do
                for x=0,v.width-1 do
                    local tid = v.data[1 + x + y * v.width]

                    if tid ~= 0 then
                        v.batch:add(map.current.tiles[tid],
                                    v.offsetx + x * map.current.tilewidth,
                                    v.offsety + y * map.current.tileheight)
                    end
                end
            end
        elseif v.type == 'objectlayer' then
        end
    end
end

--[[
    rendering functions
--]]

function map.render()
    for k, v in ipairs(map.current.layers) do
        if v.type == 'tilelayer' then
            love.graphics.draw(v.batch)
        elseif v.type == 'objectlayer' then
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
