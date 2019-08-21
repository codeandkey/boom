--- Load Trigger object type.
-- Transitions game between maps when the player interacts with it.

local log = require 'log'
local map = require 'map'

return {
    init = function(this)
        this.destination = this.destination or 'main_menu'
    end,

    interact = function(this, caller)
        if caller.__typename == 'player' then
            map.request(this.destination, this.entry_point)
        else
            log.debug('ignoring interact from object type %s', caller.__typename)
        end
    end,
}
