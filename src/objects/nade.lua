--[[
    nade.lua
    grenade object
--]]

local nade_width = 16
local nade_height = 16

return {
    init = function(self)
    end,
    destroy = function(self)
	obj.create('explosion', {x = self.x, y = self.y})
    end,
    update = function(self, dt)
    	--logic
	self.x = self.x + self.velocity * dt
    end,
    render = function(self)
        love.graphics.setColor(1, 0, 1, 1)
        love.graphics.rectangle('line', self.x, self.y, player_width, player_height)
    end,
}
