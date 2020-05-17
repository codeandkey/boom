--- Object group class.

local log          = require 'log'
local object_types = require 'object_types'
local object       = require 'object'

local object_group = {}

--- Initialize an object group from a Tiled map.
-- @param tiled_obj Lua object parsed from map file.
-- @return The object group interface.
function object_group.init(tiled_obj)
	local new_group = { objects = {} }
	local preloaded_objects = tiled_obj.objects

	-- Pass through some of the values from tiled.
	new_group.name = tiled_obj.name
	new_group.type = tiled_obj.type

	-- Initialize each real object from every preloaded object.
	for _, v in ipairs(preloaded_objects) do
		local initial = v.properties

		initial.x = v.x
		initial.y = v.y
		initial.w = v.width
		initial.h = v.height
		initial.visible = v.visible
		initial.angle = v.rotation
		initial.name = v.name

		object_group.create_object(new_group, v.type, initial)
	end

	return new_group
end

--- Remove dead objects from a group.
-- @param group Object group to clean
function object_group.remove_dead(group)
	for k, v in pairs(group.objects) do
		if v.__dead then
			object.destruct(v)
			group.objects[k] = nil
		end
	end
end

--- Unload and release all resources from a group.
-- This will destroy every object in the group.
-- @param group Group to unload
function object_group.unload(group)
	for _, v in pairs(group.objects) do
		object.destroy(v)
	end

	object_group.remove_dead(group)
end

--- Call a handler on each object (if present)
-- @param group Group to operate on
-- @param func Handler name to call
-- @param ... Arguments to pass to handler.
function object_group.call(group, func, ...)
	for _, v in pairs(group.objects) do
		object.call(v, func, ...)
	end
end

--- Search for an object by name.
-- Returns nil if the object is not found.
--
-- @param group Group to search in
-- @param name Object name to search for
-- @return The object if found, otherwise nil
function object_group.find(group, name)
	for _, v in pairs(group.objects) do
		if v.name == name then
			return v
		end
	end
end

--- Collect all objects of a certain type.
-- Returns an array of all matching objects in this layer.
--
-- @param group Group to search in
-- @param type_name Type name to search for
-- @return An array of objects of type _type\_name_.
function object_group.find_type(group, type_name)
	local output = {}

	for _, v in pairs(group.objects) do
		if v.__typename == type_name then
			table.insert(output, v)
		end
	end

	return output
end

--- Call a function with every object in the layer.
-- @param group Object group to iterate.
-- @param func Function to call.
-- @param ... Extra arguments to pass.
function object_group.foreach(group, func, ...)
	for _, v in pairs(group.objects) do
		func(v, ...)
	end
end

--- Create a new object and add it to the group.
-- @param group Object group to add to.
-- @param type_name Type name of new object.
-- @param initial Initial state of new object.
-- @return The newly created object, or nil if an error occurs
function object_group.create_object(group, type_name, initial)
	-- Check the typename.
	local obj_type = object_types[type_name]

	if obj_type == nil then
		return
	end

	-- Assign the internal layer and typename.
	initial.__layer = group
	initial.__typename = type_name

	if group == nil then
		log.error('object_group.create_object: group is nil, type_name=%s, initial=%s', type_name, initial)
	end

	-- Initialize the object and push it to the layer.
	table.insert(group.objects, object.construct(obj_type, initial))

	return initial
end

return object_group
