local log = require 'log'
local object = require 'object'

return {
    init = function(this)
        log.debug('Initializing test object!')

        -- Subscribe to input events so the character is controlled by the user.
        object.subscribe(this, 'inputdown')
        object.subscribe(this, 'inputup')

        object.add_component(this, 'character', { x = this.x, y = this.y })
    end,
}
