--[[
    camera.lua

    camera system
--]]

local camera = {
    x = 0,
    y = 0,
    w = 300,
    h = 240,
}

function camera.set(x, y, w)
    local sw, sh = love.graphics.getDimensions()
    local ratio = sh / sw

    camera.w = w or camera.w
    camera.h = camera.w * ratio
    camera.x = x + camera.w / 2
    camera.y = y
end

function camera.apply()
    local sw, sh = love.graphics.getDimensions()

    love.graphics.push()
    love.graphics.translate(-(camera.x - camera.w / 2), -(camera.y - camera.h / 2))
    love.graphics.scale(sw / camera.w, sh / camera.h)
end

function camera.unapply()
    love.graphics.pop()
end

return camera
