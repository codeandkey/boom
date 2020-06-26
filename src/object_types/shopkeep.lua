--- NPC object type.
local map = require 'map'
local object = require 'object'

-- Type-wide constants can go here
local npc = {
    Tom = {
        color = {1, 0, 1, 1},
    },
    Fred = {
        color = {0, 1, 1, 1},
    },
    Joe = {
        color = {0.5, 1, 1, 1},
    },
    Bill = {
        color = {0.5, 1, 0.5, 1},
    },
    noname = {
        color = {1, 1, 1, 1}
    },
}

return {
    init = function(this)

        this.dx_max = 0
        this.interactable = 'true'

        -- Which NPC are we?
        this.name = this.name or 'shopkeep'
        this.mode = npc[this.name]

        -- Set the sprites to be used
        this.spriteset = this.spriteset or 'char/shopkeep/'

        -- Create a character component, but don't subsbcribe to input events.
        object.add_component(this, 'character',
                                    { x = this.x,
                                      y = this.y,
                                      dx_max = this.dx_max,
                                      spriteset = this.spriteset } )

    end,

    update = function(this, dt)
        local char = this.components.character
        -- The shopkeep should never move, die, or collide with the player and his grenades.
        -- We use the character component for dialog and to change the direction we're facing.

        map.foreach_object(function (other_obj)
            if other_obj.name == 'player' then
                if other_obj.x < this.x then
                    object.call(char, 'inputdown', 'left')
                    object.call(char, 'inputup', 'right')
                else
                    object.call(char, 'inputdown', 'right')
                    object.call(char, 'inputup', 'left')
                end
            end
        end)

    end
}
