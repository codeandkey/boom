--- Options menu.

local fs      = require 'fs'
local hud     = require 'hud'
local object  = require 'object'
local object_group = require 'object_group'
local util    = require 'util'
local options = require 'options'
local event   = require 'event'
local log     = require 'log'

return {
    init = function(this)
        -- Set state.
        this.current_button = 1
        this.button_spacing = 100
        this.button_width = 640
        this.font_size = 24
        this.font = fs.read_font('pixeled.ttf', this.font_size)

        this.modes = love.window.getFullscreenModes()
        this.selected_mode = 1

        for i, v in ipairs(this.modes) do
            if v.width == options.values.width and v.height == options.values.height then
                this.selected_mode = i
            end
        end

        this.selected_scale = 1
        this.selected_scale_speed = 2
        this.selected_scale_max = 1.2

        this.selected_vsync = options.values.flags.vsync
        this.vsync_modes = {}

        this.vsync_modes[-1] = 'ADAPTIVE'
        this.vsync_modes[0] = 'OFF'
        this.vsync_modes[1] = 'ON'

        this.fullscreen = options.values.flags.fullscreen
        this.msaa = options.values.flags.msaa

        -- Subscribe to key events.
        object.subscribe(this, 'inputdown')

        this.buttons = {}

        table.insert(this.buttons, {
            text = 'RESOLUTION: ',
            action = function(self)
                self.selected_mode = (self.selected_mode % #this.modes) + 1
            end,
            scale = 1,
        })

        table.insert(this.buttons, {
            text = 'FULLSCREEN: ',
            action = function(self)
                self.fullscreen = not self.fullscreen
            end,
            scale = 1,
        })

        table.insert(this.buttons, {
            text = 'VSYNC: ',
            action = function(self)
                self.selected_vsync = self.selected_vsync + 1

                if self.selected_vsync > 1 then
                    self.selected_vsync = -1
                end
            end,
            scale = 1,
        })

        table.insert(this.buttons, {
            text = 'APPLY',
            action = function(self)
                -- First try and apply the new mode.

                local new_mode = self.modes[self.selected_mode]
                local new_width, new_height = new_mode.width, new_mode.height

                local new_flags = {
                    fullscreen = self.fullscreen,
                    msaa = self.msaa,
                    vsync = self.selected_vsync,
                }

                if love.window.setMode(new_width, new_height, new_flags) then
                    event.push('fbsize', new_width, new_height)

                    object_group.create_object(self.__layer, 'confirm_menu', {
                        new_values = {
                            width = new_width,
                            height = new_height,
                            flags = new_flags,
                        },
                    })

                    object.destroy(self)
                else
                    log.error('Failed to set new video mode: %d by %d, fullscreen %s, vsync %d, msaa %d',
                        new_width, new_height, self.fullscreen, self.selected_vsync, self.msaa)
                end
            end,
            scale = 1,
        })

        table.insert(this.buttons, {
            text = 'BACK',
            action = function(self)
                object_group.create_object(self.__layer, 'main_menu', {})
                object.destroy(self)
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
        -- Update resolution button with current mode.
        this.buttons[1].text = string.format(
            'RESOLUTION: %dx%d',
            this.modes[this.selected_mode].width,
            this.modes[this.selected_mode].height
        )

        -- Update fullscreen button.
        local fullscreen_text = 'NO'

        if this.fullscreen then
            fullscreen_text = 'YES'
        end

        this.buttons[2].text = string.format('FULLSCREEN: %s', fullscreen_text)

        -- Update vsync button.
        this.buttons[3].text = string.format('VSYNC: %s', this.vsync_modes[this.selected_vsync])

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
