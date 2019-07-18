--- Tilesets structure.
-- Each map should have exactly one tileset -- this structure initializes in-place of the 'tilesets' field
-- initially present in the map file.

local fs = require 'fs'
local tilesets = {}

--- Initialize a tileset resource from a Tiled tileset.
-- @param tiled_obj Tilesets array from map file.
-- @return The initialized tilesets table.
function tilesets.init(tiled_obj)
    -- Enforce exactly one tileset.
    if #tiled_obj > 1 then
        log.error('Map must have exactly one tileset! (found %d)', #tiled_obj)
        return nil
    end


    -- Initialize quad table.
    tiled_obj.tiles = {}

    local ts = tiled_obj[1]
    local cur_tile = ts.firstgid
    local tw, th = ts.tilewidth, ts.tileheight

    tiled_obj.tilewidth = tw
    tiled_obj.tileheight = th

    -- Load tileset image.
    tiled_obj.texture = fs.read_texture(ts.image)

    for y=0,(ts.imageheight / th)-1 do
        for x=0,(ts.imagewidth / tw)-1 do
            tiled_obj.tiles[cur_tile] = love.graphics.newQuad(x * tw, y * th, tw, th, ts.imagewidth, ts.imageheight)
            cur_tile = cur_tile + 1
        end
    end

    return tiled_obj
end

--- Unload a tileset list.
-- Destroys any images and quads allocated.
-- @param ts Tileset to unload.
function tilesets.unload(ts)
    for _, v in ipairs(ts.tiles) do
        v:release()
    end

    ts.texture:release()
end

return tilesets
