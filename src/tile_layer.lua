--- Tile layer structure.

local tile_layer = {}

--- Initialize a tile layer.
-- Prepares a tile layer for rendering and collisions.
-- @param tiled_obj Tile layer table from map file.
-- @param tilesets_obj Tilesets table from map file.
-- @return The initialized tile layer.
function tile_layer.init(tiled_obj, tilesets_obj, physics_world)
    -- Initialize render batch.
    tiled_obj.batch = love.graphics.newSpriteBatch(tilesets_obj.texture, tiled_obj.width * tiled_obj.height, 'static')

    if tiled_obj.properties.solid then
        tiled_obj.solid = true
        tiled_obj.bodies = {}
        tiled_obj.fixtures = {}
    end

    local tw = tilesets_obj.tilewidth
    local th = tilesets_obj.tileheight
    local tileshape = love.physics.newRectangleShape(tw, th)

    for y=0,tiled_obj.height-1 do
        for x=0,tiled_obj.width-1 do
            local tid = tiled_obj.data[1 + x + y * tiled_obj.width]

            if tid ~= 0 then
                tiled_obj.batch:add(tilesets_obj.tiles[tid],
                                    tiled_obj.offsetx + x * tw,
                                    tiled_obj.offsety + y * th)

                if tiled_obj.solid then
                    local body = love.physics.newBody(physics_world,
                                                      x * tw + (tw / 2),
                                                      y * th + (th / 2), 'static')
                    local fixture = love.physics.newFixture(body, tileshape)

                    table.insert(tiled_obj.bodies, body)
                    table.insert(tiled_obj.fixtures, fixture)
                end
            end
        end
    end

    -- Save some relevant info.
    tiled_obj.tilewidth = tilesets_obj.tilewidth
    tiled_obj.tileheight = tilesets_obj.tileheight

    return tiled_obj
end

--- Unloads a tile layer.
-- Destroys any physics objects in solid layers.
-- @param layer Layer to unload.
function tile_layer.unload(layer)
    if layer.solid then
        for _, v in ipairs(layer.fixtures) do
            v:destroy()
        end

        for _, v in ipairs(layer.bodies) do
            v:destroy()
        end
    end
end

--- Render a tile layer.
-- @param layer Tile layer to render.
function tile_layer.render(layer)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(layer.batch)
end

--- Check for AABB collisions against a layer.
-- If an edge of the rectangle overlaps a tile edge is it said to NOT be colliding.
-- @param layer Tile layer to test.
-- @param rect Rectangle to test, should have numeric fields _x_, _y_, _w_, _h_.
-- @return[0] True if _rect_ intersects with a non-zero tile ID in _layer_.
-- @return[0] Rectangle of the collided tile. Will have numeric fields _x_, _y_, _w_, _h_.
-- @return[1] False if _rect_ does not intersect with any nonzero tiles in _layer_.
function tile_layer.aabb(layer, rect)
    -- Compute the bounds of the tile rect we need to test.
    
    local left = math.floor((rect.x - layer.offsetx) / layer.tilewidth)
    local right = math.ceil((rect.x + rect.w - layer.offsetx) / layer.tilewidth) - 1
    local top = math.floor((rect.y - layer.offsety) / layer.tileheight)
    local bottom = math.ceil((rect.y + rect.h - layer.offsety) / layer.tileheight) - 1

    -- Check the tile data within the integer bounds for any nonzero TIDs
    for x=left,right do
        for y=top,bottom do
            if layer.data[1 + x + y * layer.width] > 0 then
                return true, {
                    x = x * layer.tilewidth + layer.offsetx,
                    y = y * layer.tileheight + layer.offsety,
                    w = layer.tilewidth,
                    h = layer.tileheight,
                }
            end
        end
    end

    return false
end

return tile_layer
