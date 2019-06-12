--[[
    util.lua
    functions for maths and collisions, other helpers
--]]

local util = {}

--[[
    util.aabb(a, b)

    Performs an AABB collision test between <a> and <b>.
    This method expects the members 'x', 'y', 'w', 'h' to be set for each argument.
--]]

function util.aabb(a, b)
    if a.x + a.w <= b.x then return false end
    if b.x + b.w <= a.x then return false end
    if a.y + a.h <= b.y then return false end
    if b.y + b.h <= a.y then return false end

    return true
end

--[[
    util.basename(str)

    Equivalent of the POSIX basename(), grabbing the last path element.
    TODO: this might explode on windows, might need a cross-platform variant
--]]

function util.basename(str)
    return string.gsub(str, "(.*/)(.*)", "%2")
end

return util
