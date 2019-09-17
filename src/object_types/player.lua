local log    = require 'log'
local map    = require 'map'
local camera = require 'camera'
local object = require 'object'
local opts   = require 'opts'
local post   = require 'post'
local sprite = require 'sprite'

return {
    init = function(this)
        -- Subscribe to input events so the character is controlled by the user.
        object.subscribe(this, 'inputdown')
        object.subscribe(this, 'inputup')
        object.subscribe(this, 'ready')

        this.death_sequence = 0.0
        this.death_sequence_max = 0.25

        -- Unset any death sequence effects.
        post.set_grayscale(0)
        camera.setescale(0)

        -- Center the camera on the player initially.
        camera.center(this.x + this.w / 2, this.y + this.h / 2)

        this.spr_idle = sprite.create('32x32_player.png', 32, 32, 1.5)
        this.spr_walk = sprite.create('32x32_player-walk.png', 32, 32, 0.1)
        this.spr_jump = sprite.create('32x32_player-jump.png', 32, 32, 0.05)

        object.add_component(this, 'character', { x = this.x,
                                                  y = this.y,
                                                  spr_idle = this.spr_idle,
                                                  spr_walk = this.spr_walk,
                                                  spr_jump = this.spr_jump })
    end,

    ready = function(this, dest)
        -- Jump to an object if we need to.

        if dest then
            log.debug('Searching for destination %s..', dest)

            local dest_obj = map.find_object(dest)

            if dest_obj then
                -- Move character to bottom boundary.
                -- Player position will later follow in update()
                this.components.character.x = dest_obj.x + dest_obj.w / 2 - this.w / 2
                this.components.character.y = dest_obj.y + dest_obj.h - this.h

                -- Valid destination; write the save file.
                opts.set('save_location', {
                    map_name = map.get_current_name(),
                    spawn_name = dest,
                })

                opts.save()
            else
                log.debug('Invalid destination %s!', dest)
            end
        end
    end,

    update = function(this, dt)
        -- Focus the camera on the player.
        local char = this.components.character

        if char then
            camera.set_focus_x(char.x + char.w / 2 + char.dx / 2)

            -- Point the camera in the right direction.
            camera.set_focus_flip(char.direction == 'left')

            if char.jump_enabled then
                camera.set_focus_y(char.y + char.h / 2)
            end

            -- Update with panic logic always.
            camera.set_panic_point(char.x + char.w / 2, char.y + char.h / 2)

            -- Our location is the character's location.
            this.x = char.x
            this.y = char.y
            this.w = char.w
            this.h = char.h

            -- Character died. Remove the component and set our dead flag.
            if char.dead then
                this.follow_gib = char.follow_gib
                object.del_component(this, 'character')
                this.dead = true
            end
        else
            camera.set_focus_x(this.follow_gib.x)
            camera.set_focus_y(this.follow_gib.y)
            camera.set_panic_point(this.follow_gib.x, this.follow_gib.y)
        end

        -- If the character dies, start a death sequence.
        -- Slowly apply a grayscale effect and slow down time.
        -- This is a little funky because the sequence is time-dependent, while also modifying time during execution
        -- However, it will still take the same amount of time to complete every time.
        if this.dead then
            this.death_sequence = this.death_sequence + dt

            map.set_time_div(8 + this.death_sequence * 8)
            camera.setescale(this.death_sequence * 2)

            if this.death_sequence >= this.death_sequence_max then
                local loc = opts.get('save_location')
                map.request(loc.map_name, loc.spawn_name)
            end

            post.set_grayscale(math.min(this.death_sequence / this.death_sequence_max, 1.0))
        end
    end,
}
