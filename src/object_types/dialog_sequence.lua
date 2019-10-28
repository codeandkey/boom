--- Dialog sequence object type.

local object = require 'object'
local util   = require 'util'
local log    = require 'log'
local fs     = require 'fs'
local map    = require 'map'

return {
    init = function(this)
        -- Find the target sequence table.
        local status, result = util.pcall(function(seq)
            return require('sequences/' .. seq)
        end, this.sequence or 'test_sequence')

        if not status then
            object.destroy(this)
            return
        end

        this.sequence = result

        this.sequence_len = #this.sequence
        this.sequence_cur = 1

        this.dialog_box_max_width = this.dialog_box_max_width or 512
        this.dialog_font          = fs.read_font('pixeled.ttf', 6)
        this.dialog_y_dist        = 25
        this.default_char_time    = 0.03
        this.default_hold_time    = 2
    end,

    update = function(this, dt)
        -- Grab the type of the current step.
        local step_type = type(this.sequence[this.sequence_cur])

        if step_type == 'number' then
            -- Timer step. Decrement the timer and then move to the next step.
            this.sequence[this.sequence_cur] = this.sequence[this.sequence_cur] - dt

            if this.sequence[this.sequence_cur] < 0 then
                this.sequence_cur = this.sequence_cur + 1
            end
        elseif step_type == 'table' then
            -- Dialog render step. Continue typing the dialog or run the wait timer.
            local seq_obj = this.sequence[this.sequence_cur]

            -- Set any unset params
            seq_obj.char_time = seq_obj.char_time or this.default_char_time

            -- Set initial character positions / timers
            seq_obj.cur_char = seq_obj.cur_char or 0
            seq_obj.char_timer = seq_obj.char_timer or seq_obj.char_time

            -- Increment character on timer expire
            if seq_obj.char_timer < 0 then
                seq_obj.char_timer = seq_obj.char_time
                seq_obj.cur_char = seq_obj.cur_char + 1
            end

            -- Decrement char timer
            seq_obj.char_timer = seq_obj.char_timer - dt

            -- Wait for wait timer after text is typed
            if seq_obj.cur_char > string.len(seq_obj.text) then
                seq_obj.hold = (seq_obj.hold or this.default_hold_time) - dt -- neat

                -- Proceed after wait timer
                if seq_obj.hold < 0 then
                    this.sequence_cur = this.sequence_cur + 1
                end
            end
        end
    end,

    render = function(this)
        -- Grab the type of the current step.
        local step_type = type(this.sequence[this.sequence_cur])

        if step_type == 'table' then
            local seq_obj = this.sequence[this.sequence_cur]

            -- Try and locate the actor.
            seq_obj.actor_handle = seq_obj.actor_handle or map.find_object(seq_obj.actor)

            if not seq_obj.actor_handle then
                log.warn('No actor ' .. seq_obj.actor .. ' found for dialog sequence!')
                return
            end

            -- With the actor present, render the current dialog text.
            local current_text = seq_obj.text:sub(0, seq_obj.cur_char or 0)

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(this.dialog_font)
            love.graphics.printf(current_text,
                                 seq_obj.actor_handle.x + seq_obj.actor_handle.w / 2 - this.dialog_box_max_width / 2,
                                 seq_obj.actor_handle.y - this.dialog_y_dist,
                                 this.dialog_box_max_width, 'center')
        end
    end,
}
