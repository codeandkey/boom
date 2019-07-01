--[[
    physbox.lua

    physics object
    the physbox can be either static or dynamic.
    this is controlled by the string parameter 'type', which defaults to 'static'.

    render color is selected by 'r', 'g', 'b', 'a', and an optional image by 'image'
--]]

local map = require 'map'
local util = require 'util'
local physics_groups = require 'physics_groups'

return {
    init = function(self)
        self.shape = love.physics.newRectangleShape(self.w, self.h)

        self.body = love.physics.newBody(map.get_physics_world(),
                                         self.x + self.w / 2,
                                         self.y + self.h / 2,
                                         self.type or 'static')

        self.fixture = love.physics.newFixture(self.body, self.shape)

        if self.image then
            self.image = love.graphics.newImage('assets/sprites/' .. util.basename(self.image))
        end

        -- apply physics group
        self.fixture:setCategory(physics_groups.PHYSBOX)
        self.fixture:setMask(physics_groups.GIB)
    end,
    render = function(self)
        love.graphics.setColor(self.r or 1, self.g or 1, self.b or 1, self.a or 1)

        local x, y = self.body:getPosition()

        love.graphics.push()
        love.graphics.translate(x, y)
        love.graphics.rotate(self.body:getAngle())

        if self.image then
            love.graphics.draw(self.image, -self.w / 2, -self.h / 2)
        else
            love.graphics.rectangle('fill', -self.w / 2, -self.h / 2, self.w, self.h)
        end

        love.graphics.pop()
    end
}
