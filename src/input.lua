--- Input mapping subsbystem.

local input = {
    keybinds = {
        left = 'left',
        right = 'right',
        down = 'down',
        up = 'up',
        z = 'jump',
        x = 'throw',
        space = 'ok',
        ['return'] = 'ok',
        c = 'interact',
    }
}

--- Translate a key value to an input name.
function input.translate(key)
    return input.keybinds[key]
end

return input
