--- Collection of game shaders.

local shaders = {}

shaders.flash = love.graphics.newShader([[
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        color.a = Texel(tex, texture_coords).a;
        return color;
    }
]])

shaders.grayscale = love.graphics.newShader([[
    uniform float level;

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
        vec4 smp = Texel(tex, texture_coords);
        float lum = dot(smp, vec4(0.2126, 0.7152, 0.0722, 0.0));
        return level * vec4(lum, lum, lum, smp.a) + (1.0 - level) * smp;
    }
]])

return shaders
