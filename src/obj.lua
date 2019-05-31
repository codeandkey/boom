--[[
    obj.lua
    functions for creating and manipulating generic objects

    the object system maintains its own list of active objects
    each object is a table with the following fields:
        __type    : object functable
        __destroy : destroy flag, once 'true' will be destroyed on next step
--]]

local util = require 'util'
local obj = {}

function obj.create(typename, initial)
    initial.__type = require('objects/' .. typename)
    initial.__destroy = false

    if initial.__type.init ~= nil then
        initial.__type.init(initial, params)
    end

    return initial
end

function obj.destroy(handle)
    handle.__destroy = true
end

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

function obj.render_layer(layer)
    for i, v in pairs(layer) do
        if v.__type.render ~= nil then
            v.__type.render(v)
        end
    end
end

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
