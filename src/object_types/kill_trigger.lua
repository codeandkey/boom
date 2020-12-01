-- Trigger which kills objects it touches.

local object = require 'object'
local util = require 'util'

return {
    update = function(self, _) {
        map.foreach_object(function(obj) {
            if util.aabb(self, obj) then
                object.call(obj, 'kill')
            end
        })
    }
}
