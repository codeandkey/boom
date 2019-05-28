--[[
    obj.lua
    functions for creating and manipulating generic objects
--]]

local obj = {}

function obj.create(typename, x, y)
    otype = require('objects/' .. typename)

    local ohandle = { __type = otype, x=x, y=y }
    otype.init(ohandle)

    return ohandle
end

function obj.destroy(handle)
    handle.__type.destroy(handle)
end

function obj.update(handle, dt)
    handle.__type.update(handle, dt)
end

function obj.render(handle)
    handle.__type.render(handle)
end

return obj
