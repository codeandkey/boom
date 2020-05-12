local log          = require 'log'
local map          = require 'map'
local camera       = require 'camera'
local object       = require 'object'
local object_group = require 'object_group'
local opts         = require 'opts'
local post         = require 'post'
local sprite       = require 'sprite'
local fs     = require 'fs'
local util   = require 'util'

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

        -- use player sprites
        this.spriteset = 'char/player/'

	      this.spr_key = sprite.create('16x16_blank-key.png', 16, 16, 0)

        this.pre_quit = false
        this.quit_font = fs.read_font('pixeled.ttf', 8)
        this.quit_y_dist   = 4
        this.quit_y_counter = 0
        this.quit_alpha = 0

	this.pre_interactable = false
        this.interact_font = fs.read_font('pixeled.ttf', 5)
	this.interact_alpha = 0
	this.interact_y_dist = 4
	this.interact_y_counter = 0

	-- create storage for interactable object once we find it
	this.interactable = {}

        object.add_component(this, 'character', { x = this.x,
                                                  y = this.y,
                                                  spriteset = this.spriteset })

        object_group.create_object(this.__layer, 'dialog_sequence', {})
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

        this.quit_y_counter = this.quit_y_counter + dt
        this.interact_y_counter = this.interact_y_counter + dt

	-- quit text fade
        if this.pre_quit then
            this.quit_alpha = math.min(this.quit_alpha + dt, 1)
        end

        if not this.pre_quit then
            this.quit_alpha = math.max(0, this.quit_alpha - 2 * dt)
        end


	-- fade prompt, check if still colliding with interactable
	-- if pre_interactable is true we know interactable has some value
        if this.pre_interactable then
            this.interact_alpha = math.min(this.interact_alpha + dt, 0.8)

            if not util.aabb(char, this.interactable) then
		this.pre_interactable = false
	    end
        end

        if not this.pre_interactable then
            this.interact_alpha = math.max(0, this.interact_alpha - 2 * dt)
        end


        -- interact prompt fade
	-- this feels.. wrong..
	map.foreach_object(function (other_obj)
            if other_obj ~= this and other_obj.interactable == 'true' and util.aabb(char, other_obj) then
	        this.interactable = other_obj
		this.pre_interactable = true
            end
	end)
    end,

    inputdown = function(this, inp)
        if inp == 'quit_to_menu' then
            if this.pre_quit then
                map.request('main_menu')
            else
                this.pre_quit = true
            end
        else
            this.pre_quit = false
        end
    end,

    render = function(this)
        if this.pre_quit then
            local quit_text = 'PRESS [ESC] AGAIN TO QUIT.'
            local quit_width = 512
            local quit_x = this.x + this.w / 2 - quit_width / 2
            local quit_y = this.y - 30 + math.sin(this.quit_y_counter) * this.quit_y_dist


	    -- set font for text
            love.graphics.setFont(this.quit_font)

	    -- display quit prompt
            love.graphics.setColor(1, 1, 1, this.quit_alpha)
            love.graphics.printf(quit_text, quit_x, quit_y, quit_width, 'center')
        end
	if this.pre_interactable then
	    -- set this to the binding for interact
            local interact_key = 'C'

	    -- interact prompt width should be the size of the sprite
            local interact_width = 16
            local interact_x = this.x + this.w / 2 - interact_width / 2
            local interact_y = this.y -20 + math.sin(this.interact_y_counter) * this.interact_y_dist

	    -- set font for text
            love.graphics.setFont(this.interact_font)

	    --display interact prompt
	    love.graphics.setColor(1,1,1, this.interact_alpha)
            sprite.render(this.spr_key, interact_x-1, interact_y-1)
	    love.graphics.printf(interact_key, interact_x, interact_y, interact_width, 'center')
        end
    end
}
