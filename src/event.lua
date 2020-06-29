--- Subsystem for manging game events and subscriptions.
--
-- Event types are documented here.
--
-- |    SIGNATURE    |                       DESCRIPTION                          |
-- | --------------- | ---------------------------------------------------------- |
-- | `ready ()`      | Called by the map after all objects have been initialized. |
-- | `keydown (key)` | Called by the display manager when _key_ is pressed.       |
-- | `keyup (key)`   | Called by the display manager when _key_ is released.      |
-- | `fbsize (w, h)` | Called when the framebuffer is resized.

local log  = require 'log'
local util = require 'util'

local event = {
    subscriptions = {}
}

--- Subscribe to an event.
-- Makes a new subscription to 'event_name' events.
-- 'callback' is called on event evaluation, with <userdata> as the first arguments
-- The callback can consume the event early by returning true.
-- More arguments may be passed to the callback depending on the event.
-- The returned object is the subscription. Call :destroy() on the subscription object to unsubscribe from the event.
--
-- @param event_name Event name to subscribe to.
-- @param callback Callback function for subscription.
-- @param userdata First arguments for callback (optional)
--
-- @return The subscription object.
function event.subscribe(event_name, callback, userdata)
    if event.subscriptions[event_name] == nil then
        event.subscriptions[event_name] = {}
    end

    local sublist = event.subscriptions[event_name]

    local sub_object = {
        event_name = event_name,
        callback = callback,
        valid = true,
        destroy = function(this)
            this.valid = false
        end,
    }

    if userdata then
        sub_object.userdata = util.pack(userdata)
    end

    log.debug('Subscribed handler object %s to event type %s', sub_object, event_name)

    table.insert(sublist, sub_object)
    return sub_object
end

--- Push a new event to the queue.
-- Events are not evaluated immediately -- they are queued and then processed in the
-- order they are received.
-- @param event_name Type of event to push.
-- @param ... Arguments to pass to subscriber callbacks.
function event.push(event_name, ...)
    local event_obj = {
        event_name = event_name,
        args = util.pack(...),
    }

    if event.tail then
        event.tail.next = event_obj
    else
        event.head = event_obj
    end

    event.tail = event_obj
end

--- Evalute the next event on the queue.
-- @return The event processed, or nil if no more events.
function event.next()
    local current = event.head

    -- check there is an event
    if current == nil then
        return nil
    end

    -- call any subscriptions
    local sublist = event.subscriptions[current.event_name]

    if sublist then
        for k, v in pairs(sublist) do
            if v.valid then
                -- valid subscription, make the call
                local status, result = false, nil

                if v.userdata then
                    status, result = util.pcall(v.callback, unpack(v.userdata, v.userdata.n), unpack(current.args, current.args.n))
                else
                    status, result = util.pcall(v.callback, unpack(current.args))
                end

                -- "consume" the event, preventing other objects from receiving it.
                if status and (result == true) then
                    break
                end
            else
                -- subscription no longer valid, destroy it
                sublist[k] = nil
            end
        end
    end

    -- advance the linked list
    event.head = event.head.next

    -- clean up tail if we reach it
    if event.head == nil then
        event.tail = nil
    end

    return current
end

--- Process the event queue until no events remain.
function event.run()
    while event.next() do end
end

return event
