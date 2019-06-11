--[[
    sprite.lua
    sprite helper interface

    each sprite object has the following properties and methods:

    local spr = sprite.create('my_texture.png', 32, 32, 0.5)
    ( create a sprite from my_texture.png with frame size 32x32 and 0.5 second frame delay )

    spr.looping [boolean]   | enable/disable automatic animation looping.
                            | this will keep the animation running once the last
                            | frame is reached and wrap back around to the first.

    spr.image [Texture]     | the spritesheet texture. should be used to render
                            | in conjunction with the Quad from spr:frame()

    spr:stop()              | stops the animation and returns to the first frame
    spr:pause()             | pauses the animation
    spr:play()              | starts the animation from wherever it left off
    spr:update(dt)          | advances the animation state by <dt> seconds
    spr:frame() [Quad]      | returns a Quad for the current frame

    spr:render(x, y, angle) | draws the sprite at (<x>, <y>),
                            | rotated about the center by <angle>,
                            | flipped if <flip> is truthy
--]]

local assets = require 'assets'
local sprite = {}

--[[
    sprite.create(tex_path) creates a new sprite object with the texture from
    <tex_path>. the path prefix is stripped from <tex_path> and the
    'assets/sprites/' directory is searched for the texture.

    returns the sprite object.
--]]

function sprite.create(tex_path, frame_w, frame_h, duration)
    local out = { frames = {} }

    -- load the spritesheet texture
    out.image = assets.image(tex_path)
    out.image_w, out.image_h = out.image:getDimensions()

    -- verify non-overlapping frames fit into the image
    if (out.image_w % frame_w > 0) or (out.image_h % frame_h > 0) then
        local tmpl = 'error: %s: frame (%d, %d) does not divide image (%d, %d)!'
        print(string.format(tmpl, tex_path, frame_w, frame_h, out.image_w, out.image_h))
        assert(false)
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
    out.playing = false
    out.looping = true

    out.frame = function(self)
        return self.frames[self.current]
    end

    out.update = function(self, dt)
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

    out.play = function(self)
        self.playing = true
        self.time_accumulator = 0
    end

    out.pause = function(self)
        self.playing = false
    end

    out.stop = function(self)
        self.playing = false
        self.current = 1
    end

    out.render = function(self, x, y, angle, flipped)
        local sx = 1

        if flipped then
            sx = -1
        end

        local iw, ih = self.image:getDimensions()

        love.graphics.draw(self.image, self:frame(), x + iw / 2, y + ih / 2, angle or 0, sx, 1, iw / 2, ih / 2)
    end

    return out
end

return sprite
