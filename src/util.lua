--[[
    util.lua
    functions for maths and collisions
--]]

local util = {}

function util.aabb(a, b)
    if a.x + a.w < b.x then return false end
    if b.x + b.w < a.x then return false end
    if a.y + a.h < b.y then return false end
    if b.y + b.h < a.y then return false end

    return true
end
