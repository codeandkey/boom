--- Post-processing pipeline manager.
-- Controls the game rendering pipeline and any post-processing effects.

local event   = require 'event'
local shaders = require 'shaders'

local post = {
	ready = false,
	effects = {
		grayscale = 0,
	},
}

--- Prepare a new frame for drawing. Should be called before any game rendering.
-- Changes the render target to an offscreen texture.
function post.begin_frame()
	-- Go ahead and initialize FBs if we haven't already.
	if not post.ready then
		post.resize()
	end

	love.graphics.setCanvas(post.fb_game)
	love.graphics.clear()
end

function post.end_frame()
	-- Perform post-processing steps.
	-- We only have 1 post shader right now, so just blit it back onto the screen without any alpha blending.

	local source = post.fb_game

	love.graphics.setBlendMode('alpha', 'premultiplied')
	love.graphics.setColor(1, 1, 1, 1)

	-- Apply grayscale effect
	source = post.apply_grayscale(source)

	love.graphics.setShader()
	love.graphics.setCanvas()
	love.graphics.clear()
	love.graphics.draw(source)

	-- Re-enable alpha blending for game drawing.
	love.graphics.setBlendMode('alpha')
end

--- Set grayscale effect intensity
-- @param amt Effect intensity. 1 is total grayscale, 0 disables the effect.
function post.set_grayscale(amt)
	post.effects.grayscale = amt
end

--- Apply grayscale effect in pipeline.
-- Used internally by post.
-- @param src Source framebuffer.
-- @return The new source framebuffer.
function post.apply_grayscale(src)
	-- Pass through the source if the effect is disabled.
	if post.effects.grayscale == 0 then
		return src
	end

	-- Apply the effect.
	love.graphics.setShader(shaders.grayscale)
	shaders.grayscale:send('level', post.effects.grayscale)

	love.graphics.setCanvas(post.fb_grayscale)
	love.graphics.draw(src)

	return post.fb_grayscale
end

--- Reinitializes the offscreen framebuffers used in post processing.
-- Called automatically via event subscription.
function post.resize()
	post.fb_game = love.graphics.newCanvas()
	post.fb_grayscale = love.graphics.newCanvas()
	post.ready = true
end

-- Watch for resize events and reconstruct the offscreen framebuffers.
event.subscribe('fbsize', post.resize)

return post
