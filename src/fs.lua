--- Interface for reading and writing to the local disk.

local log  = require 'log'
local util = require 'util'

local fs = {
    -- prefix constants. defines the location of game resources
    prefixes = {
        maps = 'src/assets/maps/',
        sprites = 'assets/sprites/',
    }
}

--- Read a map from the disk.
-- Attempts to load _name_.lua from the map prefix (assets/maps).
-- @param name Map name to load.
-- @return The map table, or nil if an error occurs.
function fs.read_map(name)
    local path = fs.prefixes.maps .. name .. '.lua'
    log.debug('Loading map %s from %s.', name, path)

    local status, result = pcall(function() return dofile(path) end)

    if status then
        return result
    else
        log.error("Couldn't load map %s!", name)
    end
end

--- Read a texture from the disk.
-- Attempts to load a sprite from the sprite prefix (assets/sprites).
-- Any path prefixes are stripped off the beginning of the texture name.
-- @param name Texture name to load.
-- @return The loaded texture, or nil if an error occurs.
function fs.read_texture(name)
    local path = fs.prefixes.sprites .. util.basename(name)
    local status, result = pcall(love.graphics.newImage, path)

    if status then
        return result
    else
        log.error("Couldn't load texture %s! (for %s)", path, name)
    end
end

return fs
