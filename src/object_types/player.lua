local camera = require 'camera'
local object = require 'object'
local sprite = require 'sprite'

return {
    init = function(this)
        -- Subscribe to input events so the character is controlled by the user.
        object.subscribe(this, 'inputdown')
        object.subscribe(this, 'inputup')

        this.spr_idle = sprite.create('32x32_player.png', 32, 32, 0.25)
        this.spr_walk = sprite.create('32x32_player-walk.png', 32, 32, 0.1)
        this.spr_jump = sprite.create('32x32_player-jump.png', 32, 32, 0.05)

        object.add_component(this, 'character', { x = this.x, y = this.y }, this.spr_idle, this.spr_walk, this.spr_jump)
    end,

    update = function(this)
        -- Focus the camera on the player.
        local char = this.components.character
        camera.set_focus_x(char.x + char.w / 2 + char.dx / 2)

        -- Point the camera in the right direction.
        camera.set_focus_flip(char.direction == 'left')

        if char.jump_enabled then
            camera.set_focus_y(char.y + char.h / 2)
        end

        -- Destroy the player if the character dies.
        if char.dead then
            object.destroy(this)
        end

        -- Our location is the character's location.
        -- We'll center for convienence.
        this.x = char.x + char.w / 2
        this.y = char.y + char.h / 2
    end,
}
