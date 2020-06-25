--- HUD rendering subsystem
-- This file contains lots of functions for rendering HUD elements in screenspace and worldspace.

local camera = require 'camera'
local fs     = require 'fs'

local hud = {
    elements = {},
    TEXTBOX = {
        BORDER_COLOR = {0, 0, 0, 1},
        BORDER_WIDTH = 2,
        TEXT_COLOR   = {0, 0, 0, 1},
        BG_COLOR     = {8, 8, 8, 1},
        PADDING      = 6,
        ARROW_SIZE   = 32,
        ARROW_DIST   = 8,
        MAX_WIDTH    = 256,
    },
}

--- Initializes the hud subsystem.
-- Loads HUD font.
function hud.init()
    hud.font = fs.read_font('pixeled.ttf', 13)
end

function hud.start()
    hud.elements = {}
end

function hud.textbox(x, y, w, h, content, align, coordmode)
    table.insert(hud.elements, {
        type = 'textbox',
        x = x or 0,
        y = y or 0,
        w = w or 256,
        h = h or 64,
        content = content or '',
        align = align or true,
        coordmode = coordmode or 'world',
    })
end

function hud.dialogbox(actor, content, w, h)
    table.insert(hud.elements, {
        type = 'dialogbox',
        actor = actor,
        w = w or hud.font:getWidth(content),
        h = h or hud.font:getHeight(),
        content = content or '',
    })
end

function hud.render()
    for _, v in ipairs(hud.elements) do
        if v.type == 'textbox' then
            -- convert coordinates
            if v.coordmode == 'world' then
                v.x, v.y, v.w, v.h = camera.to_screenspace(v.x, v.y, v.w, v.h)
            end

            -- backdrop
            love.graphics.setColor(hud.TEXTBOX.BG_COLOR)
            love.graphics.rectangle(
                'fill',
                v.x - hud.TEXTBOX.PADDING,
                v.y - hud.TEXTBOX.PADDING,
                v.w + 2 * hud.TEXTBOX.PADDING,
                v.h + 2 * hud.TEXTBOX.PADDING
            )

            -- border
            love.graphics.setColor(hud.TEXTBOX.BORDER_COLOR)
            love.graphics.setLineWidth(hud.TEXTBOX.BORDER_WIDTH)
            love.graphics.rectangle(
                'line',
                v.x - hud.TEXTBOX.PADDING,
                v.y - hud.TEXTBOX.PADDING,
                v.w + 2 * hud.TEXTBOX.PADDING,
                v.h + 2 * hud.TEXTBOX.PADDING
            )

            -- content
            love.graphics.setColor(hud.TEXTBOX.TEXT_COLOR)
            love.graphics.printf(v.content, hud.font, v.x, v.y, v.w, v.align)
        end

        if v.type == 'dialogbox' then
            -- find actor top center
            local tcx, tcy = v.actor.x + v.actor.w / 2, v.actor.y

            -- compute screenspace refpoint
            local rx, ry = camera.to_screenspace(tcx, tcy)

            -- get dimensions
            local w, wrap = hud.font:getWrap(v.content, hud.TEXTBOX.MAX_WIDTH)
            local h = table.getn(wrap) * hud.font:getHeight()

            w = math.max(w, 2 * hud.TEXTBOX.ARROW_SIZE)

            -- grab relevant points
            local x, y = rx - w / 2, ry - (hud.TEXTBOX.ARROW_DIST + hud.TEXTBOX.ARROW_SIZE) - h

            -- backdrop
            love.graphics.setColor(hud.TEXTBOX.BG_COLOR)
            love.graphics.rectangle(
                'fill',
                x - hud.TEXTBOX.PADDING,
                y - hud.TEXTBOX.PADDING,
                w + 2 * hud.TEXTBOX.PADDING,
                h + 2 * hud.TEXTBOX.PADDING
            )

            -- border
            love.graphics.setColor(hud.TEXTBOX.BORDER_COLOR)
            love.graphics.setLineWidth(hud.TEXTBOX.BORDER_WIDTH)
            love.graphics.rectangle(
                'line',
                x - hud.TEXTBOX.PADDING,
                y - hud.TEXTBOX.PADDING,
                w + 2 * hud.TEXTBOX.PADDING,
                h + 2 * hud.TEXTBOX.PADDING
            )

            -- arrow
            local arrow_points = {
                rx, ry - hud.TEXTBOX.ARROW_DIST,
                rx - hud.TEXTBOX.ARROW_SIZE, ry - (hud.TEXTBOX.ARROW_SIZE + hud.TEXTBOX.ARROW_DIST),
                rx + hud.TEXTBOX.ARROW_SIZE, ry - (hud.TEXTBOX.ARROW_SIZE + hud.TEXTBOX.ARROW_DIST),
            }

            local arrow_border_points = {
                rx - hud.TEXTBOX.ARROW_SIZE + hud.TEXTBOX.PADDING,
                ry - (hud.TEXTBOX.ARROW_SIZE + hud.TEXTBOX.ARROW_DIST) + hud.TEXTBOX.PADDING,
                rx, ry - hud.TEXTBOX.ARROW_DIST,
                rx + hud.TEXTBOX.ARROW_SIZE - hud.TEXTBOX.PADDING,
                ry - (hud.TEXTBOX.ARROW_SIZE + hud.TEXTBOX.ARROW_DIST) + hud.TEXTBOX.PADDING,
            }

            love.graphics.setColor(hud.TEXTBOX.BG_COLOR)
            love.graphics.polygon('fill', arrow_points)

            love.graphics.setColor(hud.TEXTBOX.BORDER_COLOR)
            love.graphics.line(arrow_border_points)

            -- content
            love.graphics.setColor(hud.TEXTBOX.TEXT_COLOR)
            love.graphics.printf(v.content, hud.font, x, y, w, 'center')
        end
    end
end

return hud
