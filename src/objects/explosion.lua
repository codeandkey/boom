--[[
    nade.lua
    grenade object
--]]

local ex_width = 32
local ex_height = 32
local damaging = true

return {
    init = function(self)
    end,
    destroy = function(self)
    end,
    update = function(self, dt)
    end,
    render = function(self)
        love.graphics.setColor(1, 0, 1, 1)
        love.graphics.rectangle('line', self.x, self.y, ex_width, ex_height)
    end,
}
