--- Dialog subsystem
-- Manages lifecycle of dialog sequences.

local hud  = require 'hud'
local fs   = require 'fs'
local log  = require 'log'
local map  = require 'map'

local dialog = {
    active = nil,
    CHARDELAY = 0.03,
    WAITDELAY = 2,
}

--- Selects a dialog sequence to run and then executes it.
-- @param ... One or more dialog sequence names. One is selected randomly.
function dialog.run_sequence(...)
    if #arg == 0 then
        log.warn('dialog.run_sequence() called without any arguments, skipping..')
        return
    end

    local seq = select(math.random(select('#', ...)), ...)

    -- Try and load the sequence.
    local seqobj = fs.read_sequence(seq)

    if seqobj == nil then
        return
    else
        -- Cancel all interfering sequences
        local cur = dialog.active

        while cur ~= nil do
            for _, v in cur.seqobj do
                for _, k in seqobj do
                    if k.actor == v.actor then
                        cur.state = 'dead'
                    end
                end
            end

            cur = cur.next
        end

        log.debug('Starting sequence %s.', seq)

        local entry = {
            seqobj = seqobj,
            seqname = seq,
            line = 1,
            charindex = 1,
            state = 'typing',
            timer = 0,
            next = dialog.active,
        }

        if dialog.active ~= nil then
            dialog.active.prev = entry
        end

        dialog.active = entry
    end
end

--- Updates the dialog state.
-- @param dt Elapsed seconds since last update.
function dialog.update(dt)
    local cur = dialog.active

    while cur ~= nil do
        if cur.state == 'dead' then
            if cur.prev ~= nil then
                cur.prev.next = cur.next
            else
                dialog.active = cur.next
            end

            if cur.next ~= nil then
                cur.next.prev = cur.prev
            end
        elseif cur.state == 'typing' then
            cur.timer = cur.timer + dt

            if cur.timer >= dialog.CHARDELAY then
                cur.timer = 0
                cur.charindex = cur.charindex + 1

                if cur.charindex >= string.len(cur.seqobj[cur.line].text) then
                    cur.state = 'waiting'
                end
            end
        elseif cur.state == 'waiting' then
            cur.timer = cur.timer + dt

            if cur.timer >= dialog.WAITDELAY then
                cur.timer = 0
                cur.state = 'typing'
                cur.line = cur.line + 1
                cur.charindex = 1

                if cur.line > #cur.seqobj then
                    cur.state = 'dead'
                end
            end
        end

        cur = cur.next
    end
end

--- Immediately advances all dialog sequences.
-- If a line is typing, it is skipped to the wait.
-- If a line is waiting, it is destroyed.
function dialog.skip()
    -- Skip all currently typing dialogs to the end state.
    local cur = dialog.active

    while cur ~= nil do
        if cur.state == 'typing' then
            cur.state = 'waiting'
            cur.timer = 0
            cur.charindex = string.len(cur.seqobj[cur.line].text)
        elseif cur.state == 'waiting' then
            cur.state = 'dead'
        end

        cur = cur.next
    end
end

--- Renders dialog elements using hud.
function dialog.render()
    local cur = dialog.active

    while cur ~= nil do
        -- Render all live sequences.

        if cur.state == 'typing' or cur.state == 'waiting' then
            local render_text = cur.seqobj[cur.line].text:sub(1, cur.charindex)
            local actor_obj = map.find_object(cur.seqobj[cur.line].actor)

            if actor_obj then
                hud.dialogbox(actor_obj, render_text)
            end
        end

        cur = cur.next
    end
end

return dialog
