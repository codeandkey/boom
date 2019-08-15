--- Main menu object type.
-- Main menu buttons include:
-- - New game. Switches to the first level without importing any save data.
-- - Options. Opens an options menu.
-- - Quit. Quits the game.
--
-- Options menu buttons include:
-- - Video mode. Contains 'Windowed' and a list of fullscreen modes.
-- - Vertical sync. Controls vsync modes. (on/off)
-- - MSAA. Controls multisampling buffers. (0-4)
-- - OK button, confirms options and waits 5 seconds to confirm video mode.
-- - Cancel button, disregards changes and returns to main menu.

local camera  = require 'camera'
local event   = require 'event'
local fs      = require 'fs'
local log     = require 'log'
local map     = require 'map'
local object  = require 'object'
local opts    = require 'opts'
local strings = require 'strings'

return {
    init = function(this)
        -- Initialize the font for rendering menu elements.
        this.font = fs.read_font('pixeled.ttf', 32)
        this.subfont = fs.read_font('pixeled.ttf', 16)

        -- Constants.
        this.STATE_MAIN            = 0
        this.STATE_OPTIONS         = 1
        this.STATE_OPTIONS_CONFIRM = 2
        this.CONFIRM_TIMER_LEN     = 10

        -- State.
        this.state = this.STATE_MAIN
        this.option = 1
        this.main_menu_option = 1
        this.options_menu_option = 1
        this.confirm_menu_option = 1
        this.confirm_timer = 0

        -- Subscribe to input events.
        object.subscribe(this, 'inputdown')

        this.load_current_mode = function(self)
            log.info('Detecting current mode..')

            -- Grab options and state from the current video mode.
            -- Enumerate available modes on the host.
            self.modes = {
                { type = 'windowed' }
            }

            for k, mode in ipairs(love.window.getFullscreenModes()) do
                mode.type = 'fullscreen'
                self.modes[k + 1] = mode
            end

            -- Locate the current video mode.
            local w, h, flags = love.window.getMode()

            -- Grab the current flags for vsync and msaa.
            self.option_vsync = flags.vsync
            self.option_msaa = flags.msaa
            self.option_fullscreen = flags.fullscreen

            if self.option_vsync == 0 then
                self.option_vsync = false
            end

            log.debug('detected mode %d by %d, fullscreen %s, vsync %s, msaa %d',
                      w, h, flags.fullscreen, flags.vsync, flags.msaa)
        end

        -- Helper functions for manipulating modes.
        this.set_mode = function(_, w, h, flags)
            love.window.setMode(w, h, flags)
            love.window.restore()

            w, h, flags = love.window.getMode()

            log.debug('main_menu object set mode: %d by %d, fullscreen %s, vsync %s, msaa %d',
                      w, h, tostring(flags.fullscreen), tostring(flags.vsync), flags.msaa)

            event.push('fbsize', w, h)
        end

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
        log.debug('Handling inputdown: %s', key)

        if key == 'crouch' then
            this.option = this.option + 1
        end

        if key == 'jump' then
            this.option = this.option - 1
        end

        -- Handle video mode switching.
        if this.state == this.STATE_OPTIONS and this.options_menu_option == 1 then
            if key == 'left' or key == 'right' then
                this.option_fullscreen = not this.option_fullscreen
            end
        end

        -- Handle vsync switching.
        if this.state == this.STATE_OPTIONS and this.options_menu_option == 2 then
            if key == 'left' or key == 'right' then
                this.option_vsync = not this.option_vsync
            end
        end

        -- Handle msaa switching.
        if this.state == this.STATE_OPTIONS and this.options_menu_option == 3 then
            if key == 'left' then
                this.option_msaa = math.max(this.option_msaa - 1, 0)
            elseif key == 'right' then
                this.option_msaa = math.min(this.option_msaa + 1, 4)
            end
        end

        if key == 'ok' then
            if this.state == this.STATE_MAIN then
                -- Handle main menu buttons.

                if this.main_menu_option == 1 then
                    -- New game!
                    -- Load the main map.
                    map.request('intro')
                elseif this.main_menu_option == 2 then
                    this.state = this.STATE_OPTIONS
                    this.option = 1
                    this:load_current_mode()
                elseif this.main_menu_option == 3 then
                    -- Quit game!
                    love.event.quit(0)
                end
            elseif this.state == this.STATE_OPTIONS then
                -- Handle options menu buttons.
                -- Most options are selectors -- just handle confirm/cancel buttons.

                if this.options_menu_option == 4 then
                    -- Confirm button. Apply video settings and move to confirm menu.

                    -- Grab the current mode and save it.
                    this.last_w, this.last_h, this.last_flags = love.window.getMode()
                    local w, h, flags = love.window.getMode()

                    flags.msaa = this.option_msaa
                    flags.vsync = this.option_vsync
                    flags.fullscreen = this.option_fullscreen

                    this:set_mode(w, h, flags)

                    -- Switch state and set the confirm timer.
                    this.state = this.STATE_OPTIONS_CONFIRM
                    this.option = 1
                    this.confirm_timer = this.CONFIRM_TIMER_LEN
                elseif this.options_menu_option == 5 then
                    -- Return to main menu without applying or saving options.
                    this.state = this.STATE_MAIN
                    this.option = 1
                end
            elseif this.state == this.STATE_OPTIONS_CONFIRM and this.confirm_timer < this.CONFIRM_TIMER_LEN - 1 then
                -- Handle confirm menu options.
                if this.confirm_menu_option == 1 then
                    -- Revert settings and return to options menu.
                    log.info('Reverting settings.')
                    this:set_mode(this.last_w, this.last_h, this.last_flags)
                    this.state = this.STATE_OPTIONS
                    this.option = 1
                    this:load_current_mode()
                else
                    -- Settings are OK. Save the new mode to the opts.
                    local w, h, flags = love.window.getMode()

                    opts.set('mode', {
                        width = w,
                        height = h,
                        flags = flags
                    })

                    opts.save()

                    -- Return to the main menu.
                    this.state = this.STATE_MAIN
                    this.option = 1
                end
            end
        end

        -- Keep selections in bounds by wrapping
        this.main_menu_option = ((this.option - 1) % 3) + 1
        this.options_menu_option = ((this.option - 1) % 5) + 1
        this.confirm_menu_option = ((this.option - 1) % 2) + 1
    end,

    update = function(this, dt)
        -- Wait for confirmation.
        if this.state == this.STATE_OPTIONS_CONFIRM then
            this.confirm_timer = this.confirm_timer - dt

            if this.confirm_timer < 0 then
                -- Timer expired. Restore the last OK video mode and return to the options menu.
                log.info('Confirm timer expired. Restoring last mode.')
                this:set_mode(this.last_w, this.last_h, this.last_flags)
                this.state = this.STATE_OPTIONS
                this.option = 1
                this:load_current_mode()
            end
        end
    end,

    render = function(this)
        -- Grab camera rect so we can print stuff in worldspace.
        local cb = camera.get_bounds()

        love.graphics.setColor(1, 1, 1, 1)

        if this.state == this.STATE_MAIN then
            -- Draw the title.
            this:draw_element(strings.get('MAIN_MENU_TITLE'), cb.x + cb.w / 2, cb.y + cb.h / 4, this.font, false)

            -- Draw main options.
            this:draw_element(strings.get('MAIN_MENU_NEW'),
                              cb.x + cb.w / 2, cb.y + cb.h / 2,
                              this.subfont, this.main_menu_option == 1)

            this:draw_element(strings.get('MAIN_MENU_OPTIONS'),
                              cb.x + cb.w / 2, cb.y + cb.h / 2 + this.subfont:getHeight(),
                              this.subfont, this.main_menu_option == 2)

            this:draw_element(strings.get('MAIN_MENU_QUIT'),
                              cb.x + cb.w / 2, cb.y + cb.h / 2 + 2 * this.subfont:getHeight(),
                              this.subfont, this.main_menu_option == 3)

        elseif this.state == this.STATE_OPTIONS then
            -- Render video mode option.
            local video_mode_text = strings.get('OPTIONS_MENU_MODE')

            if this.option_fullscreen then
                video_mode_text = video_mode_text .. 'FULLSCREEN'
            else
                video_mode_text = video_mode_text .. 'WINDOW'
            end

            this:draw_element(video_mode_text,
                              cb.x + cb.w / 2, cb.y + cb.h / 6,
                              this.subfont, this.options_menu_option == 1)

            -- Render vertical sync option.
            local vsync_text = strings.get('OPTIONS_MENU_VSYNC')

            if this.option_vsync then
                vsync_text = vsync_text .. 'ON'
            else
                vsync_text = vsync_text .. 'OFF'
            end

            this:draw_element(vsync_text,
                              cb.x + cb.w / 2, cb.y + 2 * (cb.h / 6),
                              this.subfont, this.options_menu_option == 2)

            -- Render MSAA option.
            local msaa_text = strings.get('OPTIONS_MENU_MSAA') .. tostring(this.option_msaa)

            if this.option_msaa == 0 then
                msaa_text = msaa_text .. ' (OFF)'
            end

            this:draw_element(msaa_text,
                              cb.x + cb.w / 2, cb.y + 3 * (cb.h / 6),
                              this.subfont, this.options_menu_option == 3)

            -- Render OK and cancel buttons.
            --
            this:draw_element(strings.get('OPTIONS_MENU_OK'),
                              cb.x + cb.w / 2, cb.y + 4 * (cb.h / 6),
                              this.subfont, this.options_menu_option == 4)

            this:draw_element(strings.get('OPTIONS_MENU_CANCEL'),
                              cb.x + cb.w / 2, cb.y + 5 * (cb.h / 6),
                              this.subfont, this.options_menu_option == 5)

        elseif this.state == this.STATE_OPTIONS_CONFIRM then
            -- Render confirm message.

            this:draw_element(strings.get('CONFIRM_MENU_TITLE') .. ' (' .. math.ceil(this.confirm_timer) .. ')',
                              cb.x + cb.w / 2, cb.y + cb.h / 4,
                              this.subfont, false)

            -- Render confirm options.

            this:draw_element(strings.get('CONFIRM_MENU_CANCEL'),
                              cb.x + cb.w / 2, cb.y + 2 * (cb.h / 4),
                              this.subfont, this.confirm_menu_option == 1)

            this:draw_element(strings.get('CONFIRM_MENU_OK'),
                              cb.x + cb.w / 2, cb.y + 3 * (cb.h / 4),
                              this.subfont, this.confirm_menu_option == 2)
        end
    end,
}
