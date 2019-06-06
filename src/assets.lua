--[[
    assets.lua
    interface for loading assets
--]]

local util = require 'util'
local assets = {}

local prefixes = {
    sprites = 'assets/sprites/',
    maps    = 'assets/maps/',
}

local sprite_cache = {}

--[[
    assets.sprite(file)

    loads a cached Image from a filename or path.
    only the last part of the path is considered.
    EG: if file = '/tmp/player.png', the function will load from 'assets/sprites/player.png'
--]]

function assets.sprite(file)
    local path = prefixes.sprites .. util.basename(file)

    if sprite_cache[path] == nil then
        sprite_cache[path] = love.graphics.newImage(path)
    end

    return sprite_cache[path]
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
