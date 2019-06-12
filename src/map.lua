--[[
    map.lua
    functions for loading/managing tile-based maps
--]]

local assets = require 'assets'
local obj = require 'obj'
local map = {}

--[[
    map.load(name)

    Loads a Lua map from assets/maps/<name>.lua
    The map should be exported from Tiled. (File -> Export Map)

    Initializes tileset textures, objects, and all other resources in the map
--]]

function map.load(name)
    map.current = assets.map(name)
    map.current.tiles = {}

    -- initialize the physics world for the map
    map.current.phys_world = love.physics.newWorld(0, map.current.properties.gravity or 9.8 * 16)

    -- for now, only allow one tileset
    -- this is because batches can only go through one image and dividing
    -- that will be very painful when loading
    assert(#map.current.tilesets <= 1)

    -- initialize tilesets
    for _, v in ipairs(map.current.tilesets) do
        v.texture = assets.image(v.image)

        -- create quads for each tile in the set
        local cur_tile = v.firstgid
        local tw, th = v.tilewidth, v.tileheight

        for y=0,(v.imageheight/v.tileheight)-1 do
            for x=0,(v.imagewidth/v.tilewidth)-1 do
                map.current.tiles[cur_tile] = love.graphics.newQuad(x * tw, y * th, tw, th, v.imagewidth, v.imageheight)
                cur_tile = cur_tile + 1
            end
        end
    end

    -- initialize layers
    for _, v in ipairs(map.current.layers) do
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
        elseif v.type == 'objectgroup' then
            -- object init is pretty quick. we pass the map properties as the template
            -- the object structure doesn't mesh well with the obj system so we embed
            -- a new object list (boom_layer).
            v.boom_layer = {}

            for _, object in ipairs(v.objects) do
                local initial = object.properties
                initial.x = object.x
                initial.y = object.y
                initial.w = object.width
                initial.h = object.height
                initial.name = object.name
                initial.angle = object.rotation
                initial.__layer = v.boom_layer

                obj.create(v.boom_layer, object.type, initial)
            end
        end
    end
end

--[[
    map.update(dt)

    Updates the state of all objects in the map by <dt> seconds.
--]]

function map.update(dt)
    map.current.phys_world:update(dt)

    for _, v in ipairs(map.current.layers) do
        -- for now, we only need to update object layers
        if v.type == 'objectgroup' then
            obj.update_layer(v.boom_layer, dt)
        end
    end
end

--[[
    map.render()

    Renders all of the map content, including all tiles and all objects.
    Layers which have 'visible' unset will be ignored.
    Layer order is respected.
--]]

function map.render()
    for _, v in ipairs(map.current.layers) do
        if v.visible then
            love.graphics.setColor(1, 1, 1, 1)

            if v.type == 'tilelayer' then
                love.graphics.draw(v.batch)
            elseif v.type == 'objectgroup' then
                obj.render_layer(v.boom_layer)
            end
        end
    end
end

--[[
    map.layer_by_name(name)

    Locates an OBJECT LAYER by it's name and returns it.
    If no layer matches <name> then nil is returned.
--]]

function map.layer_by_name(name)
    for _, v in ipairs(map.current.layers) do
        if v.name == name then
            return v.boom_layer
        end
    end

    return nil
end

function map.get_physics_world()
    return map.current.phys_world
end

--[[
    map.render_phys_debug()

    renders physics debugging information
--]]

function map.render_phys_debug()
    love.graphics.setColor(0, 0, 1, 1)

    for _, body in ipairs(map.current.phys_world:getBodies()) do
        for _, fixture in ipairs(body:getFixtures()) do
            local shape = fixture:getShape()
            local shape_type = shape:getType()

            if shape_type == 'polygon' then
                love.graphics.polygon('line', body:getWorldPoints(shape:getPoints()))
            elseif shape_type == 'circle' then
                love.graphics.circle('line', body:getX(), body:getY(), shape:getRadius())
            end
        end
    end
end

return map
