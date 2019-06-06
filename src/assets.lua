--[[
    assets.lua
    interface for loading assets
--]]

local util = require 'util'
local assets = {}

local prefixes = {
    images  = 'assets/sprites/',
    maps    = 'assets/maps/',
}

local image_cache = {}

--[[
    assets.image(file)

    loads a cached Image from a filename or path.
    only the last part of the path is considered.
    EG: if file = '/tmp/player.png', the function will load from 'assets/sprites/player.png'
--]]

function assets.image(file)
    local path = prefixes.images .. util.basename(file)

    if image_cache[path] == nil then
        image_cache[path] = love.graphics.newImage(path)
    end

    return image_cache[path]
end

--[[
    assets.map(name)

    loads a map from assets/maps/<name>.lua , except a unique object is
    returned every time (as maps are mutated at runtime)
--]]

function assets.map(name)
    return require(prefixes.maps .. name)
end

return assets
