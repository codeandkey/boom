--- Main menu object type.

local camera = require 'camera'
local fs     = require 'fs'
local map    = require 'map'
local object = require 'object'

return {
    init = function(this)
        -- Initialize the font for rendering menu elements.
        this.font = fs.read_font('pixeled.ttf', 32)
        this.subfont = fs.read_font('pixeled.ttf', 16)

        -- Constants.
        this.STATE_MAIN    = 0
        this.STATE_OPTIONS = 1
        this.WRAP_LIMIT    = 256

        this.strings = {
            TITLE_TEXT     = 'BOOM',
            NEW_GAME_TEXT  = 'NEW GAME',
            LOAD_GAME_TEXT = 'LOAD GAME',
            OPTIONS_TEXT   = 'OPTIONS',
            QUIT_TEXT   = 'QUIT GAME',
        }

        -- State.
        this.state = this.STATE_MAIN
        this.main_menu_option = 1

        -- Subscribe to input events.
        object.subscribe(this, 'inputdown')

        -- Helper member function to draw an element with an optional selector.
        this.draw_element = function(self, str, x, y, font, selected)
            font = font or self.font

            -- Compute text boundaries.
            local tw, th = font:getWidth(str), font:getHeight()

            love.graphics.setFont(font)

            -- Render centered option.
            love.graphics.print(str, x - tw / 2, y - th / 2)

            -- If selected, render selector tris.
            if selected then
                love.graphics.polygon('fill', x - tw / 2 - th / 2, y,
                                              x - tw / 2 - th, y - th / 4,
                                              x - tw / 2 - th, y + th / 4)
                love.graphics.polygon('fill', x + tw / 2 + th / 2, y,
                                              x + tw / 2 + th, y - th / 4,
                                              x + tw / 2 + th, y + th / 4)
            end
        end
    end,

    inputdown = function(this, key)
        if key == 'crouch' then
            if this.state == this.STATE_MAIN then
                this.main_menu_option = this.main_menu_option + 1
            end
        end

        if key == 'jump' then
            if this.state == this.STATE_MAIN then
                this.main_menu_option = this.main_menu_option - 1
            end
        end

        if key == 'ok' then
            if this.state == this.STATE_MAIN then
                if this.main_menu_option == 1 then
                    -- New game!
                    -- Load the main map.
                    map.load('test')
                elseif this.main_menu_option == 3 then
                    -- Quit game!
                    love.event.quit(0)
                end
            end
        end

        -- Keep selections in bounds by wrapping
        this.main_menu_option = ((this.main_menu_option - 1) % 3) + 1
    end,

    update = function(this, dt)
    end,

    render = function(this)
        -- Grab camera rect so we can print stuff in worldspace.
        local cb = camera.get_bounds()
        local fh = this.font:getHeight()

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(this.font)

        if this.state == this.STATE_MAIN then
            -- Draw the title.
            this:draw_element(this.strings.TITLE_TEXT, cb.x + cb.w / 2, cb.y + cb.h / 4, this.font, false)
            
            -- Draw main options.
            this:draw_element(this.strings.NEW_GAME_TEXT, cb.x + cb.w / 2, cb.y + cb.h / 2, this.subfont, this.main_menu_option == 1)
            this:draw_element(this.strings.OPTIONS_TEXT, cb.x + cb.w / 2, cb.y + cb.h / 2 + this.subfont:getHeight(), this.subfont, this.main_menu_option == 2)
            this:draw_element(this.strings.QUIT_TEXT, cb.x + cb.w / 2, cb.y + cb.h / 2 + 2 * this.subfont:getHeight(), this.subfont, this.main_menu_option == 3)
        end
    end,
}
