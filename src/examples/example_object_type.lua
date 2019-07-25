--- Example object type.

local log    = require 'log'
local object = require 'object'

return {
    --- Object constructor. Called when added to a layer (during loading or runtime).
    -- @param this Initial object state.
    init = function(this)
        -- if 'my_message' is set then it will be used, otherwise use a default message.
        this.my_message = this.my_message or 'Default message!'

        -- Print the message to the console.
        log.debug('Constructing example object. My message is: %s', this.my_message)

        -- Subscribe to all key presses.
        object.subscribe(this, 'keydown')
    end,

    --- Object destructor. Called when the object is destroyed.
    -- @param this Object being destroyed.
    destroy = function(this)
        -- Print a message to the console.
        log.debug('Destroying example object! %s', this)

        -- We don't actually have any destroy logic needed here.
        -- All events are optional. This function can be safely removed.
    end,

    --- Object update handler. Called on every update.
    -- @param this Object to update.
    -- @param dt Delta time (seconds).
    update = function(this, dt)
        log.debug('Updating example object by %f seconds! %s', dt, this)
    end,

    --- Object render handler. Called on every render.
    -- @param this Object to render.
    render = function(this)
        -- Draw a white rectangle covering the object.
        -- Every object has the fields 'x', 'y', 'w', 'h'.
        -- (this.x, this.y) designates the location of the top left corner of the object,
        -- and (this.w, this.h) designates the dimensions of the rectangle as defined in the map file.

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle('fill', this.x, this.y, this.w, this.h)
    end,

    --- Custom event handler (keydown)
    -- In the 'init' event, we subscribed to the 'keydown' event.
    -- So, whenever a key is pressed we will receive a call to 'keydown' with the key passed as the first arg.
    -- (information on the 'keydown' event can be found in /event.lua )
    keydown = function(this, key)
        -- Just write the key to stdout.
        log.debug('Example object received key down: %s! (%s)', key, this)
    end,
}
