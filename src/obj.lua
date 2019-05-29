--[[
    obj.lua
    functions for creating and manipulating generic objects

    the object system maintains its own list of active objects
    each object is a table with the following fields:
        __type    : object functable
        __destroy : destroy flag, once 'true' will be destroyed on next step
--]]

local obj = { object_list = {} }

function obj.create(typename, initial)
    initial.__type = require('objects/' .. typename)
    initial.__destroy = false
    initial.__type.init(initial, params)

    table.insert(obj.object_list, initial)

    return initial
end

function obj.destroy(handle)
    handle.__destroy = true
    handle.__type.destroy(handle)
end

function obj.update_all(dt)
    for i, v in pairs(obj.object_list) do
        if v.__destroy then
            -- drop this object out of the array and proceed
            v.__type.destroy(v)
            obj.object_list[i] = nil
        else
            v.__type.update(v, dt)
        end
    end
end

function obj.render_all()
    for i, v in pairs(obj.object_list) do
        v.__type.render(v)
    end
end

return obj
