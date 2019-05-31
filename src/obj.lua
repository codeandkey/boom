--[[
    obj.lua
    functions for creating and manipulating generic objects

    the object system maintains its own list of active objects
    each object is a table with the following fields:
        __type    : object functable
        __destroy : destroy flag, once 'true' will be destroyed on next step
--]]

local obj = {}

function obj.create(typename, initial)
    initial.__type = require('objects/' .. typename)
    initial.__destroy = false
    initial.__type.init(initial, params)

    return initial
end

function obj.destroy(handle)
    handle.__destroy = true
    handle.__type.destroy(handle)
end

function obj.update_layer(layer, dt)
    for i, v in pairs(layer) do
        if v.__destroy then
            -- drop this object out of the array and proceed
            v.__type.destroy(v)
            layer[i] = nil
        else
            v.__type.update(v, dt)
        end
    end
end

function obj.render_layer(layer)
    for i, v in pairs(layer) do
        v.__type.render(v)
    end
end

function obj.get_collisions(handle, layer)
    local output = {}

    for i, v in pairs(layer) do
        if v ~= handle and v.__solid and util.aabb(handle, v) then
            table.insert(output, v)
        end
    end

    return output
end

return obj
