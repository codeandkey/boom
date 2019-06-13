--[[
    camera.lua

    camera system
--]]

local camera = { shake = 0 }

function camera.set(x, y, w)
    local sw, sh = love.graphics.getDimensions()
    local ratio = sh / sw

    camera.w = w or camera.w
    camera.h = camera.w * ratio
    camera.x = x
    camera.y = y

    camera.left = camera.x - camera.w / 2
    camera.top = camera.y - camera.h / 2
    camera.bottom = camera.top + camera.h
    camera.right = camera.x + camera.w
end

function camera.apply()
    local sw, sh = love.graphics.getDimensions()
    local ox, oy = 0, 0

    if camera.shake > 0 then
        camera.shake = camera.shake / 1.1
        ox = (math.random() * 2.0 - 1.0) * camera.shake
        oy = (math.random() * 2.0 - 1.0) * camera.shake
    end

    love.graphics.push()
    love.graphics.scale(sw / camera.w, sh / camera.h)
    love.graphics.translate(-(camera.x - camera.w / 2) + ox, -(camera.y - camera.h / 2) + oy)
end

function camera.unapply()
    love.graphics.pop()
end

function camera.setshake(shake)
    camera.shake = shake
end

camera.set(0, 0, 600)

return camera
