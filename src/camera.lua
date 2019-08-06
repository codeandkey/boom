--- Camera subsystem.
-- The game will look "crispest" if we scale pixels properly (no half-pixels ever rendered).
-- So, we apply the camera using only a scale and a translate to center on the screen.

local event = require 'event'
local log   = require 'log'

local camera = {
    x = 0, -- center coordinates
    y = 0,
    scale = 2, -- pixel scale (effective viewport size)
    focus_x = 0,
    focus_y = 0,
    max_game_width = 640, -- maximum camera width in game coordinates

    focus_box = {
        left = 0.3,
        right = 0.4,
        top = 0.45,
        bottom = 0.55,
    },

    panic_box = {
        left = 0.1,
        right = 0.9,
        top = 0.1,
        bottom = 0.9,
    },

    anim_xspeed = 1, -- Higher is slower.
    anim_yspeed = 0.5,

    shake_factor = 15,
    shake_time = 0,
}

--- Center the game camera on a point.
-- @param x X coordinate.
-- @param y Y coordinate.
function camera.center(x, y)
    camera.x = x
    camera.y = y
end

--- Set the camera shake time.
-- @param Time to shake for (seconds).
function camera.setshake(shake)
    camera.shake_time = shake
end

--- Set the size (in display pixels) for 1 game pixel.
-- @param scale Display scale.
function camera.setscale(scale)
    camera.scale = scale
end

--- Get the camera bounding rectangle.
-- @return Table with _x_, _y_, _w_, _h_ in world space.
function camera.get_bounds()
    local sw, sh = love.graphics.getDimensions()
    local cw, ch = (sw / camera.scale), (sh / camera.scale)

    return {
        x = camera.x - cw / 2,
        y = camera.y - ch / 2,
        w = cw,
        h = ch
    }
end

--- Get the camera center.
-- @return X coordinate.
-- @return Y coordinate.
function camera.get_center()
    return camera.x, camera.y
end

--- Apply the camera settings to the graphics context.
-- Every call to @{camera.apply} should be matched with a call to @{camera.unapply}.
function camera.apply()
    -- Grab the current dimensions to find the screen center.
    local sw, sh = love.graphics.getDimensions()

    love.graphics.push()
    love.graphics.translate(sw / 2, sh / 2)
    love.graphics.scale(camera.scale)
    love.graphics.translate(-camera.x, -camera.y)

    -- Apply extra translate if shaking.
    if camera.shake_time > 0 then
        love.graphics.translate(((math.random() * 2) - 1) * camera.shake_time * camera.shake_factor,
                                ((math.random() * 2) - 1) * camera.shake_time * camera.shake_factor)
    end
end

--- Update the camera's scale from a display size.
-- Should be called whenever the framebuffer is resized.
-- @param w Framebuffer width.
function camera.rescale(w, h)
    log.debug('Rescaling camera for framebuffer size %d, %d', w, h)
    camera.scale = 1

    while w / camera.scale > camera.max_game_width do
        camera.scale = camera.scale + 1
    end
end

--- Unapply the camera settings in the graphics context.
function camera.unapply()
    love.graphics.pop()
end

--- Set the camera focus X.
-- @param x X coordinate.
function camera.set_focus_x(x)
    camera.focus_x = x
end

--- Enable or disable mirroring of the focus box.
-- @param enabled Flipping enabled if true.
function camera.set_focus_flip(enabled)
    camera.flip_x = enabled
end

--- Set the camera focus Y.
-- @param y Y coordinate.
function camera.set_focus_y(y)
    camera.focus_y = y
end

-- Animate the camera towards the focus point.
-- @param dt Update time (seconds).
function camera.update(dt)
    local sw, sh = love.graphics.getDimensions()

    -- Get camera dimensions in world space.
    local cw, ch = (sw / camera.scale), (sh / camera.scale)

    -- Get the camera boundaries in world space.
    local cam_bounds = {
        left = camera.x - cw / 2,
        right = camera.x + cw / 2,
        top = camera.y - ch / 2,
        bottom = camera.y + ch / 2,
    }

    -- Get the focus box boundaries in world space.
    local fbox_world = {
        top = cam_bounds.top + ch * camera.focus_box.top,
        bottom = cam_bounds.top + ch * camera.focus_box.bottom,
    }

    -- Flip the focus box over the screen center if needed.
    if camera.flip_x then
        fbox_world.left = cam_bounds.right - cw * camera.focus_box.right
        fbox_world.right = cam_bounds.right - cw * camera.focus_box.left
    else
        fbox_world.left = cam_bounds.left + cw * camera.focus_box.left
        fbox_world.right = cam_bounds.left + cw * camera.focus_box.right
    end

    -- Get the panic box boundaries in world space.
    local pbox_world = {
        top = cam_bounds.top + ch * camera.panic_box.top,
        bottom = cam_bounds.top + ch * camera.panic_box.bottom,
        left = cam_bounds.left + cw * camera.panic_box.left,
        right = cam_bounds.left + cw * camera.panic_box.right,
    }

    -- Move the camera to keep the focus point in the box.
    local vx = nil
    local vy = nil

    if camera.focus_x > fbox_world.right then
        -- Move the camera right.
        vx = dt * (camera.focus_x - fbox_world.right) / camera.anim_xspeed
    elseif camera.focus_x < fbox_world.left then
        -- Move the camera left.
        vx = dt * (camera.focus_x - fbox_world.left) / camera.anim_xspeed
    end

    if camera.focus_y > fbox_world.bottom then
        -- Move the camera down.
        vy = dt * (camera.focus_y - fbox_world.bottom) / camera.anim_yspeed
    elseif camera.focus_y < fbox_world.top then
        -- Move the camera up.
        vy = dt * (camera.focus_y - fbox_world.top) / camera.anim_xspeed
    end

    -- Immediately move the camera to keep the focus point in the panic box.
    if camera.focus_x < pbox_world.left then
        vx = camera.focus_x - pbox_world.left
    elseif camera.focus_x > pbox_world.right then
        vx = camera.focus_x - pbox_world.right
    end

    if camera.focus_y < pbox_world.top then
        vy = camera.focus_y - pbox_world.top
    elseif camera.focus_y > pbox_world.bottom then
        vy = camera.focus_y - pbox_world.bottom
    end

    -- Finally update the camera position.
    camera.x = camera.x + (vx or 0)
    camera.y = camera.y + (vy or 0)

    -- Update the shake timer.
    camera.shake_time = camera.shake_time - dt
end

--- Render camera debug information.
function camera.render_debug()
    local sw, sh = love.graphics.getDimensions()

    -- Get camera dimensions in world space.
    local cw, ch = (sw / camera.scale), (sh / camera.scale)

    -- Draw the focus point in cyan.
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.line(camera.focus_x - 10, camera.focus_y, camera.focus_x + 10, camera.focus_y)
    love.graphics.line(camera.focus_x, camera.focus_y - 10, camera.focus_x, camera.focus_y + 10)

    -- Get the camera boundaries in world space.
    local cam_bounds = {
        left = camera.x - cw / 2,
        right = camera.x + cw / 2,
        top = camera.y - ch / 2,
        bottom = camera.y + ch / 2,
    }

    -- Get the focus box boundaries in world space.
    local fbox_world = {
        top = cam_bounds.top + ch * camera.focus_box.top,
        bottom = cam_bounds.top + ch * camera.focus_box.bottom,
    }

    -- Flip the focus box over the screen center if needed.
    if camera.flip_x then
        fbox_world.left = cam_bounds.right - cw * camera.focus_box.right
        fbox_world.right = cam_bounds.right - cw * camera.focus_box.left
    else
        fbox_world.left = cam_bounds.left + cw * camera.focus_box.left
        fbox_world.right = cam_bounds.left + cw * camera.focus_box.right
    end

    -- Draw the focus boundaries in green.
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.line(cam_bounds.left, fbox_world.top, cam_bounds.right, fbox_world.top)
    love.graphics.line(cam_bounds.left, fbox_world.bottom, cam_bounds.right, fbox_world.bottom)
    love.graphics.line(fbox_world.left, cam_bounds.top, fbox_world.left, cam_bounds.bottom)
    love.graphics.line(fbox_world.right, cam_bounds.top, fbox_world.right, cam_bounds.bottom)

    -- Get the panic box boundaries in world space.
    local pbox_world = {
        top = cam_bounds.top + ch * camera.panic_box.top,
        bottom = cam_bounds.top + ch * camera.panic_box.bottom,
        left = cam_bounds.left + cw * camera.panic_box.left,
        right = cam_bounds.left + cw * camera.panic_box.right,
    }

    -- Draw the panic boundaries in blue.
    love.graphics.setColor(0, 0, 1, 1)
    love.graphics.line(cam_bounds.left, pbox_world.top, cam_bounds.right, pbox_world.top)
    love.graphics.line(cam_bounds.left, pbox_world.bottom, cam_bounds.right, pbox_world.bottom)
    love.graphics.line(pbox_world.left, cam_bounds.top, pbox_world.left, cam_bounds.bottom)
    love.graphics.line(pbox_world.right, cam_bounds.top, pbox_world.right, cam_bounds.bottom)
end

-- Global event handler for camera resizing.
event.subscribe('fbsize', camera.rescale)

return camera
