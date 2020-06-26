--- Interface for reading and writing to the local disk.

local log  = require 'log'
local util = require 'util'

local fs = {
    -- prefix constants. defines the location of game resources
    prefixes = {
        maps = 'src/assets/maps/',
        sprites = 'assets/sprites/',
        fonts = 'assets/fonts/',
        sequences = 'src/assets/sequences/',
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

--- Read a sequence from the disk.
-- Attempts to load _name_.lua from the map prefix (assets/sequences).
-- @param name Sequence name to load.
-- @return The sequence table, or nil if an error occurs.
function fs.read_sequence(name)
    local path = fs.prefixes.sequences .. name .. '.lua'
    local status, result = pcall(function() return dofile(path) end)

    if status then
        return result
    else
        log.error("Couldn't load sequence %s!", path)
    end
end

--- Loads a tileset texture from the disk.
-- This is equivalent to fs.read_texture, but the name is passed to
-- basename() before loading the file. This is because
-- Tiled stores somewhat unpredictable paths to textures sometimes.
-- @param name Texture name to load. Only the last path element is considered.
-- @return The loaded texture, or nil if an error occurs.
function fs.read_tileset(name)
    return fs.read_texture(util.basename(name))
end

--- Read a texture from the disk.
-- Attempts to load a sprite from the sprite prefix (assets/sprites).
-- Any path prefixes are stripped off the beginning of the texture name.
-- @param name Texture name to load.
-- @return The loaded texture, or nil if an error occurs.
function fs.read_texture(name)
    local path = fs.prefixes.sprites .. name
    local status, result = pcall(love.graphics.newImage, path)

    if status then
        return result
    else
        log.error("Couldn't load texture %s! (for %s)", path, name)
    end
end

--- Read a font from the disk.
-- Tries to load a font from the font prefix (assets/fonts).
-- @param name Font file suffix to load, with extension.
-- @param size Font size (pt). [default 16]
function fs.read_font(name, size)
    local path = fs.prefixes.fonts .. util.basename(name)
    local status, result = pcall(love.graphics.newFont, path, size or 16)

    if status then
        return result
    else
        log.error("Couldn't load font %s! (for %s)", path, name)
    end
end

return fs
