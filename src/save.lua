--- Save game control.

local util  = require 'util'
local log   = require 'log'

local save = {
    PATH = 'profile.lua',
}

--- Tries to load save from the disk.
-- If a save cannot be loaded, a new save is created.
-- @return true on success, false otherwise
function save.load()
    local status, result = util.execfile(save.PATH)

    if status then
        save.values = result
        save.was_loaded = true
        log.info('Loaded save game from %s.', save.PATH)
        return true
    else
        return save.newgame()
    end
end

--- Starts a new game and writes the save file.
-- @return true if successful, false otherwise.
function save.newgame()
    log.info('Starting a new save game.')

    save.values = {
        map = 'intro',
        spawn = 'intro_0',
    }

    save.was_loaded = false

    return save.write()
end

--- Writes the current save values to the disk.
-- @return true if successful, false otherwise.
function save.write()
    if util.serialize_to_file(save.values, save.PATH) then
        log.info('Wrote save game to %s.', save.PATH)
        return true
    end

    return false
end

--- Sets a save value and writes the save state.
-- If v is a table it can only contain numbers, strings, and (valid) tables.
-- @param k Key to set.
-- @param v Value to assosicate with key. Can be number, string, or table.
function save.set(k, v)
    save.values[k] = v
    save.write()
end

--- Returns save value at key.
-- @param k Key.
-- @return Value associated with key, or nil if not set.
function save.get(k)
    return save.values[k]
end

--- Returns true if a save game was loaded from the disk.
-- @return true if save loaded, false otherwise.
function save.loaded()
    return save.was_loaded
end

return save
