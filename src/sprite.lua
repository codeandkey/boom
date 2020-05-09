--- Sprite API.

local fs = require 'fs'
local log = require 'log'

local sprite = {}

--[[
    sprite.create(tex_path) creates a new sprite object with the texture from
    <tex_path>. the path prefix is stripped from <tex_path> and the
    'assets/sprites/' directory is searched for the texture.

    returns the sprite object.
--]]

--- Create a new sprite.
-- @param tex_path Texture name. Passed to @{fs.read_texture}.
-- @param frame_w Width of a single frame.
-- @param frame_h Height of a single frame.
-- @param duration Delay between frames (seconds).
-- @return The sprite object.
function sprite.create(tex_path, frame_w, frame_h, duration)
    local out = { frames = {} }

    -- load the spritesheet texture
    out.image = fs.read_texture(tex_path)
    out.image_w, out.image_h = out.image:getDimensions()

    -- fill the sprite if no frame width
    if frame_w == nil then
        frame_w = out.image_w
    end

    if frame_h == nil then
        frame_h = out.image_h
    end

    out.frame_w = frame_w
    out.frame_h = frame_h

    -- verify non-overlapping frames fit into the image
    if (out.image_w % frame_w > 0) or (out.image_h % frame_h > 0) then
        local templ = '%s: frame (%d, %d) does not divide image (%d, %d)!'
        log.error(templ, tex_path, frame_w, frame_h, out.image_w, out.image_h)
        return
    end

    -- create the quads for each frame
    out.num_frames = (out.image_w / frame_w) * (out.image_h / frame_h)
    local cur_frame = 1

    for y=0,(out.image_h / frame_h)-1 do
        for x=0,(out.image_w / frame_w)-1 do
            out.frames[cur_frame] = love.graphics.newQuad(x * frame_w,
                                                          y * frame_h,
                                                          frame_w, frame_h,
                                                          out.image_w, out.image_h)
            cur_frame = cur_frame + 1
        end
    end

    -- set up sprite state
    out.duration = duration
    out.current = 1
    out.playing = true
    out.looping = true
    out.time_accumulator = 0

    return out
end

--- Get the current sprite frame texture.
-- @param spr Sprite to query.
-- @return The current texture.
function sprite.frame(spr)
    return spr.frames[spr.current]
end

--- Get the frame size.
-- @param sprite Sprite to query.
-- @return Frame width.
-- @return Frame height.
function sprite.frame_size(spr)
    return spr.frame_w, spr.frame_h
end

--- Update a sprite by _dt_ seconds.
-- @param self Sprite to update.
-- @param dt Seconds to update by.
function sprite.update(self, dt)
    if not self.duration then
        return
    end

    if self.playing then
        self.time_accumulator = self.time_accumulator + dt

        while self.time_accumulator > self.duration do
            self.time_accumulator = self.time_accumulator - self.duration
            self.current = self.current + 1

            if self.current > self.num_frames then
                if self.looping then
                    self.current = 1
                else
                    self.current = self.num_frames
                    self.playing = false
                end
            end
        end
    end
end

--- Play or resume a sprite.
-- Will start the sprite from the beginning if it is already at the end.
-- @param self Sprite to play.
function sprite.play(self)
    self.playing = true
    self.time_accumulator = 0

    if self.current >= self.num_frames then
        self.current = 1
    end
end

--- Pause a sprite.
-- @param self Sprite to pause.
function sprite.pause(self)
    self.playing = false
end

--- Stop a sprite.
-- Pauses the sprite and moves the frame to the start.
-- @param self Sprite to stop.
function sprite.stop(self)
    self.playing = false
    self.current = 1
end

--- Render a sprite.
-- @param self Sprite to render.
-- @param x X coord for the top-left corner.
-- @param y Y coord for the top-left corner.
-- @param angle Rotation about the center.
-- @param flipped If `true`, horizontally flip the sprite.
-- @param crush Pixels to reduce image height by.
function sprite.render(self, x, y, angle, flipped, crush)
    local sx = 1

    if flipped then
        sx = -1
    end

    local iw = self.frame_w
    local ih = self.frame_h

    -- apply crush, nearest filtering should already be applied
    local sy = (ih - (crush or 0)) / ih

    love.graphics.draw(self.image, sprite.frame(self), x + iw / 2, y + ih / 2, angle or 0, sx, sy, iw / 2, ih / 2)
end

--- Reverse the order of a sprite's frames.
-- @param self Sprite to reverse.
function sprite.reverse(self)
    local new_frames = {}

    for _, v in ipairs(self.frames) do
        table.insert(new_frames, v)
    end

    self.frames = new_frames
end

return sprite
