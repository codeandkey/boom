--- Subsystem for managing Tiled-based worlds.

local camera       = require 'camera'
local log          = require 'log'
local event        = require 'event'
local fs           = require 'fs'
local tilesets     = require 'tilesets'
local object_group = require 'object_group'
local tile_layer   = require 'tile_layer'
local util         = require 'util'

local map = {
	default_gravity = 9.8 * 16,
	fade_out_speed = 4,
	fade_in_speed  = 2,
	fade_alpha = 1,
	delay_time = 0.2,
	delay_time_current = 0,
}

--- Immediately load and initialize a map.
-- Loads map from the disk, and unloads any current map.
-- @param name Map to load.
-- @param packed_args Packed arguments to pass to ready event.
function map.load(name, packed_args)
	if map.current then
		map.unload()
	end

	log.info('Loading map %s.', name)
	map.current = fs.read_map(name)

	-- Something went wrong loading the map. Stop here and leave the map unloaded.
	if map.current == nil then
		return
	end

	-- Assign map name.
	map.current.name = name

	-- Initialize physics world.
	map.current.physics_world = love.physics.newWorld(0, map.current.properties.gravity or map.default_gravity)

	-- Initialize tilesets.
	map.current.tilesets = tilesets.init(map.current.tilesets)

	-- Set default time divisor.
	map.current.time_div = 1

	-- Initialize layers.
	for k, v in ipairs(map.current.layers) do
		if v.type == 'tilelayer' then
			log.debug('Loading tile layer from index %d', k)
			map.current.layers[k] = tile_layer.init(v, map.current.tilesets, map.current.physics_world)
		elseif v.type == 'objectgroup' then
			log.debug('Loading object group from index %d', k)
			map.current.layers[k] = object_group.init(v)
		end
	end

	-- Go ahead and find the player object.
	map.current.player = map.find_object('player')

	if not map.current.player then
		log.warn('Map %s does not contain a player object. Expect problems.', map.current.name)
	end

	log.debug('Posting map ready event.')
	event.push('ready', unpack(packed_args or {n=0}))
end

--- Unload the current map, if there is one loaded.
-- Destroys all resources and content loaded in the current map.
function map.unload()
	-- Silently ignore if no map is loaded.
	if map.current == nil then
		return
	end

	log.info('Unloading map %s.', map.current.name)

	tilesets.unload(map.current.tilesets)

	for _, v in ipairs(map.current.layers) do
		if v.type == 'objectgroup' then
			object_group.unload(v)
		elseif v.type == 'tilelayer' then
			tile_layer.unload(v)
		end
	end
end

--- Get the loaded map name.
-- @return The map name, or nil if none loaded.
function map.get_current_name()
	if map.current then
		return map.current.name
	end
end

--- Get the player object.
-- @returns Player object or nil if none found.
function map.get_player()
	return map.current.player
end

--- Get the map physics world.
-- @return The active physics world or nil if no map.
function map.get_physics_world()
	if map.current == nil then
		return nil
	end

	return map.current.physics_world
end

--- Request a transition to a new map.
-- This should be used for switching maps instead of `map.load`.
-- @param name Map to switch to.
function map.request(name, ...)
	map.requested = name
	map.request_args = util.pack(...)
end

--- Update all objects in the map y _dt_ seconds.
-- Also updates the map's physics world.
-- Any objects marked for destruction are destroyed afterward.
function map.update(dt)
	-- Ignore if no map loaded.
	if map.current == nil then
		return
	end

	-- Apply time divisor.
	dt = dt / map.current.time_div

	-- Perform transition logic if a transition is happening.
	if map.requested ~= nil then
		if map.fade_alpha < 1 then
			-- Move towards a fade out.
			map.fade_alpha = map.fade_alpha + dt * map.fade_out_speed

			if map.fade_alpha > 1 then
				-- Start the in-between timer.
				map.delay_time_current = map.delay_time
			end
		else
			map.delay_time = map.delay_time - dt

			if map.delay_time < 0 then
				-- Load the next map now.
				map.load(map.requested, map.request_args)
				-- Unset the request.
				map.requested = nil
			end
		end
	else
		-- No transition requested. Fade in if we need to.
		if map.fade_alpha > 0 then
			map.fade_alpha = map.fade_alpha - dt * map.fade_in_speed
		end
	end

	for _, v in ipairs(map.current.layers) do
		if v.type == 'objectgroup' then
			object_group.call(v, 'update', dt)
			object_group.remove_dead(v)
		elseif v.type == 'tilelayer' then
			tile_layer.update(v, dt, map.current.player)
		end
	end

	map.current.physics_world:update(dt)
end

--- Render all objects in the map.
function map.render()
	-- Ignore if no map loaded.
	if map.current == nil then
		return
	end

	for _, v in ipairs(map.current.layers) do
		if v.type == 'tilelayer' then
			tile_layer.render(v)
		elseif v.type == 'objectgroup' then
			object_group.call(v, 'render')
		end
	end

	-- Render transition fade overlay.
	local cb = camera.get_bounds()

	love.graphics.setColor(0, 0, 0, map.fade_alpha)
	love.graphics.rectangle('fill', cb.x, cb.y, cb.w, cb.h)
end

--- Find a layer by name.
-- @param name Layer name to search for.
-- @return First matching layer with name or nil if not found.
function map.find_layer(name)
	if map.current == nil then
		return nil
	end

	for _, v in ipairs(map.current.layers) do
		if v.name == name then
			return v
		end
	end
end

--- Sets the time divisor for the current map.
-- A value of 2 will make the map run at half speed.
-- @param div Time divisor.
function map.set_time_div(div)
	map.current.time_div = div
end

--- Find an object by name.
-- Searches each object group for an object named <name>.
-- Returns the first valid result.
function map.find_object(name)
	if map.current == nil then
		return nil
	end

	for _, v in ipairs(map.current.layers) do
		if v.type == 'objectgroup' then
			local res = object_group.find(v, name)

			if res then
				return res
			end
		end
	end
end

--- Check for AABB collisions on all solid tile layers.
-- @param rect Rectangle to test. Should have numeric fields _x_, _y_, _w_, _h_.
-- @return[0] True if _rect_ intersects with a non-zero tile ID in _layer_.
-- @return[0] Rectangle of the collided tile. Will have numeric fields _x_, _y_, _w_, _h_.
-- @return[1] False if _rect_ does not intersect with any nonzero tiles in _layer_.
function map.aabb_tile(rect)
	for _, v in ipairs(map.current.layers) do
		if v.type == 'tilelayer' and v.properties.solid then
			local status, collision = tile_layer.aabb(v, rect)

			if status then
				return status, collision
			end
		end
	end

	return false
end

-- Execute a function on every object in the map.
-- @param func Function to call.
-- @param ... Extra arguments for function.
function map.foreach_object(func, ...)
	for _ ,v in ipairs(map.current.layers) do
		if v.type == 'objectgroup' then
			object_group.foreach(v, func, ...)
		end
	end
end

return map
