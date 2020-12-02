-- Trigger which starts the pitfall death sequence.

local object = require 'object'
local util = require 'util'
local map = require 'map'

return {
    update = function(self, _)
        if self.player_ref then
            if util.aabb(self, self.player_ref) then
                object.call(self.player_ref, 'pitfall')
            end
        else
            self.player_ref = map.find_object('player')
        end
    end
}
