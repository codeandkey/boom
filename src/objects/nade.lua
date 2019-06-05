--[[
    nade.lua
    grenade object
--]]

local nade_width = 16
local nade_height = 16

return {
    init = function(self)
	img = love.graphics.newImage('assets/sprites/16x16_nade.png') 
    end,

    destroy = function(self)
	obj.create(self.__layer, 'explosion', {x = self.x, y = self.y})
    end,

    update = function(self, dt)
    	--logic
	self.x = self.x + self.velocity * dt
    end,

    render = function(self)
	love.graphics.draw(img, self.x, self.y + nade_height, 0, 1, 1, 0, 16)
    end,
}
