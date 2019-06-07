--[[
    noclip.lua
    noclip object
--]]

local map = require 'map'

return {
    init = function(self)
        self.solid   = true
        self.body    = love.physics.newBody(map.get_physics_world(),
                                          self.x + self.w / 2,
                                          self.y + self.h / 2,
                                          'static')
        self.shape   = love.physics.newRectangleShape(self.w, self.h)
        self.fixture = love.physics.newFixture(self.body, self.shape)
    end
}
