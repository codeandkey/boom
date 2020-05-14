--- GUI subsystem

local gui = {
    elements = {},
    element_ctr = 0,

    TEXTBOX_FG = {1, 1, 1, 1},
    TEXTBOX_BG = {0, 0, 0, 0.6},
    TEXTBOX_BORDER_COLOR = {1, 1, 1, 1},
    TEXTBOX_BORDER_SIZE = 2,
}

--- Removes an element from the GUI.
function gui.remove(handle)
    if handle and handle.key then
        gui.elements[handle.key] = nil
    end
end

--- Queries the GUI rect.
-- Equivalent to the current screen size.
function gui.rect()
    return {
        x = 0,
        y = 0,
        w = love.graphics.getWidth(),
        h = love.graphics.getHeight(),
    }
end

--- Creates a generic GUI element.
-- @param typename Element type.
-- @return Newly created element.
function gui.element(typename)
    local el = {
        typename = typename,
        key = gui.element_ctr,
    }

    gui.elements[el.key] = el
    gui.element_ctr = gui_element_ctr + 1

    return el
end

--- Creates a textbox element and returns a handle to it.
-- @return New textbox element.
function gui.textbox()
    return gui.element('textbox')
end

--- Renders a single element. Called internally!
-- @param el Element to render.
function gui.draw_element(el)
    if el.typename == 'textbox' then
        -- Render bg.
        love.graphics.setColor(gui.TEXTBOX_BG)
        love.graphics.rectangle('fill', el.x, el.y, el.w, el.h)

        -- Render fg text.
        love.graphics.setColor(gui.TEXTBOX_FG)
        love.graphics.printf(el.text, el.x, el.y, el.w, el.align or 'left')

        -- Render border.
        love.graphics.setLineWidth(gui.TEXTBOX_BORDER_SIZE)
        love.graphics.setColor(gui.TEXTBOX_BORDER_COLOR)
        love.graphics.rectangle('line', el.x, el.y, el.w, el.h)
    end
end

function gui.render()
    for _, v in pairs(gui.elements) do
        util.pcall(gui.draw_element, v)
    end
end

return gui
