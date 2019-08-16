--- Object API. Also serves as the component API.
-- Each object has the following fields:
-- | Field           | Description |
-- | -----           | ----------- |
-- | __layer         | Internal field pointing to the `object_group` containing the object. |
-- | __type          | Internal field pointing to the object's type table. |
-- | __typename      | Object's type name. Used in logging messages. |
-- | __subscriptions | Table of active object event subscriptions. |
-- | components      | Table of object components. Each component is indexed by it's type name. |
-- | visible         | Boolean flag, object will not render if this is false. |
--
-- The boom object model is designed as an entity-component system.
-- While it is possible to write each object type individually, there is often code that can be
-- reused between objects. A notable example is the player, npc, and enemies. All use a common
-- 'character' component which controls a player-like character.
--
-- Objects can add these common bits in the form of components. Any events sent to an object
-- will be relayed to all of its components.

local component_types = require 'component_types'
local event           = require 'event'
local log             = require 'log'
local util            = require 'util'

local object = {}

--- Construct a new object.
-- Creates a new object from a given type table and initial state.
-- Sends the 'init' event and prepares metafields and event handlers.
-- @param type_table Type to construct from. Get from `object_types` or `component_types`.
-- @param initial_state Object table to initialize in.
-- @return The initialized object table. Will not be active in any layer until added.
function object.construct(type_table, initial_state)
    initial_state.__type = type_table
    initial_state.__subscriptions = {}
    initial_state.__dead = false

    initial_state.components = {}
    initial_state.visible = initial_state.visible or false

    object.call(initial_state, 'init')

    return initial_state
end

--- Subscribe an object to an event.
-- @param obj Object to subscribe.
-- @param event_name Event name to subscribe to.
function object.subscribe(obj, event_name)
    if obj.__subscriptions[event_name] == nil then
        obj.__subscriptions[event_name] = event.subscribe(event_name, function (_obj, ...)
            object.call(_obj, event_name, ...)
        end, obj)
    else
        log.warn('Ignoring multiple subscription to %s from object of type %s!', event_name, obj.__typename)
    end
end

--- Safely destruct an object and any allocated components / subscriptions
-- This should NEVER be called from within an object. This is handled by object groups.
-- Please see 'object.destroy(obj)' for requesting an object be destroyed.
function object.destruct(obj)
    -- Call defined destructor first
    -- It's important that we call this directly -- otherwise it will be relayed to components too early.
    util.pcall(obj.__type.destroy, obj)

    -- Clean up any subscriptions
    for _, v in pairs(obj.__subscriptions) do
        v:destroy()
    end

    -- Destroy any components
    for _, v in pairs(obj.components) do
        object.destruct(v)
    end
end

--- Mark an object for destruction.
-- This function can be safely called from anywhere in the game.
-- @param obj Object to destroy.
function object.destroy(obj)
    obj.__dead = true
end

--- Make a safe call to an object handler.
-- Will be silently ignored if the object type does not implement the function.
-- Relays the event call to every component first.
-- @param obj Object to call handler on.
-- @param name Handler to call.
-- @param ... Arguments to pass to handler.
-- @return The value returned from the handler, or nil if not implemented.
function object.call(obj, name, ...)
    for _, v in pairs(obj.components) do
        util.pcall(v.__type[name], v, ...)
    end

    local status, ret = util.pcall(obj.__type[name], obj, ...)

    if status then
        return ret
    end
end

--- Add a new component to an object.
-- @param obj Object to add to.
-- @param type_name Component type name.
-- @param initial Initial state for component.
function object.add_component(obj, type_name, initial)
    if obj.components[type_name] ~= nil then
        log.warn('Ignoring multiple init of component %s on object type %s!', type_name, obj.__typename)
        return
    end

    -- Locate component type and initialize it.
    local c_type = component_types[type_name]

    if c_type == nil then
        log.warn('Unknown component type %s, ignoring add', type_name)
        return
    end

    initial = initial or {}
    initial.__typename = type_name
    initial.__layer = obj.__layer -- Pass through layer if there is one
    initial.__parent = obj

    obj.components[type_name] = object.construct(c_type, initial)

    log.debug('Added component of type %s to object type %s', type_name, obj.__typename)
end

return object
