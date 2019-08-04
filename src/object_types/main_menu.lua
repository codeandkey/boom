--- Main menu object type.

local camera = require 'camera'
local fs     = require 'fs'

return {
    init = function(this)
        -- Initialize the font for rendering menu elements.
        this.font = fs.read_font('pixeled.ttf', 32)

        -- Constants.
        this.STATE_MAIN    = 0
        this.STATE_OPTIONS = 1
        this.WRAP_LIMIT    = 256

        this.strings = {
            TITLE_TEXT     = 'BOOM',
            NEW_GAME_TEXT  = 'NEW GAME',
            LOAD_GAME_TEXT = 'LOAD GAME',
            OPTIONS_TEXT   = 'OPTIONS',
        }

        -- State.
        this.state = this.STATE_MAIN
        this.main_menu_option = 1
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
            love.graphics.printf(this.TITLE_TEXT,
                                 cb.x,
                                 cb.y + cb.h / 4 - fh / 2,
                                 cb.w,
                                 'center')
        end
    end,
}
