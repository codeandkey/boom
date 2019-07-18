--- NPC object type.

local log    = require 'log'
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
        -- Which NPC are we?
        this.name = this.name or 'noname'
        this.mode = npc[this.name]

        -- Random movement state.
        this.thought_timer_variation = 5
        this.thought_timer_min       = 3
        this.thought_timer           = 0

        -- Create a character component, but don't subsbcribe to input events.
        -- We will generate our own.
        object.add_component(this, 'character', { x = this.x, y = this.y, color = this.mode.color })
    end,

    update = function(this, dt)
        this.thought_timer = this.thought_timer - dt

        if this.thought_timer < 0 then
            -- Perform a new thought.

            if math.random(0, 1) == 0 then
                -- Move somewhere. What direction?
                if math.random(0, 1) == 0 then
                    -- Go left!
                    object.call(this.components.character, 'inputdown', 'left')
                    object.call(this.components.character, 'inputup', 'right')
                else
                    -- Go other left!
                    object.call(this.components.character, 'inputdown', 'right')
                    object.call(this.components.character, 'inputup', 'left')
                end
            else
                -- Stop moving and wait. Release all keys.
                object.call(this.components.character, 'inputup', 'left')
                object.call(this.components.character, 'inputup', 'right')
            end
            
            -- Wait a semirandom time before thinking again.
            this.thought_timer = math.random(0, this.thought_timer_variation) + this.thought_timer_min
        end

        -- Check if we've run into a wall.
        if this.components.character.is_walking and math.abs(this.components.character.dx) < 10 then
            -- Will we try and vault it?
            if math.random(0, 2) > 0 then
                -- Send a jump keypress!
                object.call(this.components.character, 'inputdown', 'jump')

                -- Normally we'd send an 'inputup' to release the jump, but the
                -- character component doesn't actually listen for it.
            else
                -- Give up and stop walking.
                object.call(this.components.character, 'inputup', 'left')
                object.call(this.components.character, 'inputup', 'right')
            end
        end
    end
}
