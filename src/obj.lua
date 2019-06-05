--[[
    obj.lua
    functions for creating and manipulating generic objects

    the object system maintains its own list of active objects
    each object is a table with the following fields:
        __type    : object functable
        __destroy : destroy flag, once 'true' will be destroyed on next step
        __layer   : the layer containing the object
--]]

local util = require 'util'
local obj = {}

--[[
    obj.create(layer, typename, initial)

    Initializes a new object from <initial> and inserts it into <layer>.
    The object type is read from 'objects/<typename>.lua'.
    Calls the type initializer function if there is one.
    Will crash and burn if <typename> is not a valid object type.

    Returns the object created (equivalent to <initial>)
--]]

function obj.create(layer, typename, initial)
    initial.__type = require('objects/' .. typename)
    initial.__destroy = false
    initial.__layer = layer

    if initial.__type.init ~= nil then
        initial.__type.init(initial, params)
    end

    table.insert(layer, initial)

    return initial
end

--[[
    obj.destroy(handle)

    Marks the object pointed to by <handle> for destruction.
    The object is not destroyed immediately -- it is destroyed on the next update.
--]]

function obj.destroy(handle)
    handle.__destroy = true
end

--[[
    obj.update_layer(layer, dt)

    Updates all of the objects within <layer> by <dt> seconds.
--]]

function obj.update_layer(layer, dt)
    for i, v in pairs(layer) do
        if v.__destroy then
            -- drop this object out of the array and proceed
            if v.__type.destroy ~= nil then
                v.__type.destroy(v)
            end

            layer[i] = nil
        else
            if v.__type.update ~= nil then
                v.__type.update(v, dt)
            end
        end
    end
end

--[[
    obj.render_layer(layer)

    Renders all of the objects within <layer>.
--]]

function obj.render_layer(layer)
    for i, v in pairs(layer) do
        if v.__type.render ~= nil then
            v.__type.render(v)
        end
    end
end

--[[
    obj.get_collisions(handle, layer, first)

    Performs a collision test between <handle> and all solid objects within <layer>.

    Any objects without a truthy value for 'solid' are ignored in the collision test.

    If <first> is truthy then the first colliding object is returned, or nil if there are no collisions.
    If <first> is not truthy then an array of all colliding objects is returned.
--]]

function obj.get_collisions(handle, layer, first)
    local output = {}

    if layer == nil then
        if first then
            return nil
        else
            return output
        end
    end

    for i, v in pairs(layer) do
        if v ~= handle and v.solid and util.aabb(handle, v) then
            if first then
                return v
            end

            table.insert(output, v)
        end
    end

    if first then
        return nil
    else
        return output
    end
end

return obj
