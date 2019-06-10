--[[
    shaders.lua
    collection of game shaders
--]]

local shaders = {}

shaders.flash = love.graphics.newShader([[
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        color.a = Texel(tex, texture_coords).a;
        return color;
    }
]])

return shaders
