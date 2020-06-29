--- Main menu object type.

local fs      = require 'fs'
local hud     = require 'hud'
local map     = require 'map'
local object  = require 'object'
local object_group  = require 'object_group'
local save    = require 'save'
local util    = require 'util'

return {
    init = function(this)
        -- Set state.
        this.current_button = 1
        this.button_spacing = 100
        this.button_width = 400
        this.font_size = 24
        this.font = fs.read_font('pixeled.ttf', this.font_size)

        this.selected_scale = 1
        this.selected_scale_speed = 2
        this.selected_scale_max = 1.2

        -- Subscribe to key events.
        object.subscribe(this, 'inputdown')

        this.buttons = {}

        -- Add start game button. This is either a new game or continue game.

        local startgame_button_text = 'START GAME'

        if save.loaded() then
            startgame_button_text = 'CONTINUE GAME'
        end

        table.insert(this.buttons, {
            text = startgame_button_text,
            action = function()
                map.request(save.get('map'), save.get('spawn'))
            end,
            scale = 1,
        })

        -- Add a new game button as well if there is an existing save.

        if save.loaded() then
            table.insert(this.buttons, {
                text = 'NEW GAME',
                action = function()
                    save.newgame()
                    map.request(save.get('map'), save.get('spawn'))
                end,
                scale = 1,
            })
        end

        -- Add options button.

        table.insert(this.buttons, {
            text = 'SETTINGS',
            action = function(self)
                object_group.create_object(self.__layer, 'options_menu', {})
                object.destroy(self)
            end,
            scale = 1,
        })

        -- Add a quit button.

        table.insert(this.buttons, {
            text = 'QUIT GAME',
            action = function()
                love.event.quit()
            end,
            scale = 1,
        })
    end,

    inputdown = function(this, key)
        if key == 'crouch' then
            this.current_button = (this.current_button % #this.buttons) + 1
            this.selected_scale = 1
            return true
        end

        if key == 'up' then
            this.current_button = this.current_button - 1

            if this.current_button == 0 then
                this.current_button = #this.buttons
            end

            this.selected_scale = 1
            return true
        end

        if key == 'ok' or key == 'jump' then
            util.pcall(this.buttons[this.current_button].action, this)
            return true
        end
    end,

    update = function(this, dt)
        -- Update button scales.
        for i, v in ipairs(this.buttons) do
            if i == this.current_button then
                v.scale = math.min(v.scale + dt * this.selected_scale_speed, this.selected_scale_max)
            else
                v.scale = math.max(v.scale - dt * this.selected_scale_speed, 1)
            end
        end
    end,

    render = function(this)
        local sw, sh = love.graphics.getDimensions()
        local cx, cy = sw / 2, sh / 2

        -- Render all buttons in order.
        local total_height = this.button_spacing * (#this.buttons - 1) + this.font_size * #this.buttons
        local cur_y = cy - total_height / 2

        for _, v in ipairs(this.buttons) do
            hud.textbox(
                cx - this.button_width / 2,
                cur_y,
                this.button_width,
                nil,
                v.text,
                'center',
                'screen',
                this.font,
                v.scale
            )

            cur_y = cur_y + this.font_size + this.button_spacing
        end
    end,
}
