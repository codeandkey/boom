--- Input mapping subsbystem.

local input = {
	keybinds = {
		left = 'left',
		right = 'right',
		down = 'crouch',
		z = 'jump',
		x = 'throw',
		up = 'jump',
		space = 'ok',
		['return'] = 'ok',
		c = 'interact',
		escape = 'quit_to_menu',
	}
}

--- Translate a key value to an input name.
function input.translate(key)
	return input.keybinds[key]
end

return input
