-- Trigger which starts the pitfall death sequence.

local object = require 'object'
local util = require 'util'

return {
    update = function(self, _) {
        if self.player_ref then
            if util.aabb(self, self.player_ref) then
                object.call(obj, 'pitfall')
            end
        else
            self.player_ref = map.find_object('player')
        end
    }
}
