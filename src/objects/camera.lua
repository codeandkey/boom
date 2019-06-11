--[[
    camera.lua
    camera object

    the camera object has some useful member functions to help with effects:

    local cam = obj.create(..., 'camera')

    cam:center_on(x, y) -- set camera target center to (<x>, <y>)
    cam:resize(size)    -- set camera target size to <size>
--]]

local camera = require 'camera'

return {
    init = function(self)
        -- constants
        self.target_size = self.target_size or 400 -- default target size

        -- focus box dimensions. all values are ratios of the screen size
        self.focus_hbox_size = 0.15
        self.focus_vbox_size = 0.3
        self.focus_hbox_center = 0.3
        self.focus_vbox_center = 0.7

        -- anim factor for camera size. higher is faster
        self.size_anim_factor = 2

        -- camera dampening factors for each axis. higher is slower
        self.horizontal_damp = 1
        self.vertical_damp = 1.2

        -- effect of target velocity on focus box position, higher is more
        self.velocity_factor = 1

        -- state
        self.size = self.target_size
        self.target = nil
        self.focus_box = nil

        -- member functions
        -- big function for updating focus state
        self.set_focus = function(this, left, right, top, bottom, grounded, dx, dy, direction)
            if this.target == nil then
                this.target = {}
            end

            this.target.left = left
            this.target.right = right
            this.target.top = top
            this.target.bottom = bottom
            this.target.grounded = grounded
            this.target.dx = dx
            this.target.dy = dy
            this.target.direction = direction
        end

        -- useful for letting camera resolve itself while still controlling location
        self.settargetsize = function(this, target)
            this.target_size = target
        end
    end,

    update = function(self, dt)
        -- don't do anything until a target is set
        if self.target == nil then
            return
        end

        -- don't let a focus box exist until a target is set
        if self.focus_box == nil then
            self.focus_box = {}
        end

        -- update focus box boundaries
        self.focus_box.hsize = camera.w * self.focus_hbox_size
        self.focus_box.vsize = camera.h * self.focus_vbox_size

        self.focus_box.hcenter = camera.left + camera.w * self.focus_hbox_center
        self.focus_box.vcenter = camera.top + camera.h * self.focus_vbox_center

        -- if the player is facing left, flip the horizontal center by the camera center
        if self.target.direction == 'left' then
            self.focus_box.hcenter = camera.left + camera.w * (1.0 - self.focus_hbox_center)
        end

        -- push the focus box even further based on the target velocity
        self.focus_box.hcenter = self.focus_box.hcenter - self.velocity_factor * self.target.dx
        --self.focus_box.vcenter = self.focus_box.vcenter - self.velocity_factor * self.target.dy

        self.focus_box.left = self.focus_box.hcenter - self.focus_box.hsize / 2
        self.focus_box.top = self.focus_box.vcenter - self.focus_box.vsize / 2
        self.focus_box.right = self.focus_box.left + self.focus_box.hsize
        self.focus_box.bottom = self.focus_box.top + self.focus_box.vsize

        -- start motionless
        self.dx = 0
        self.dy = 0

        -- update camera horizontal velocity unconditionally
        if self.target.left < self.focus_box.left then
            self.dx = (self.target.left - self.focus_box.left) / self.horizontal_damp
        elseif self.target.right > self.focus_box.right then
            self.dx = (self.target.right - self.focus_box.right) / self.horizontal_damp
        end

        -- if player is grounded, update vertical velocity to keep in focus box
        if self.target.grounded then
            if self.target.top > self.focus_box.top then
                self.dy = (self.target.top - self.focus_box.top) / self.vertical_damp
            elseif self.target.bottom < self.focus_box.bottom then
                self.dy = (self.target.bottom - self.focus_box.bottom) / self.vertical_damp
            end
        end

        -- update camera size and position from dt
        self.size = self.size + dt * self.size_anim_factor * (self.target_size - self.size)

        self.x = self.x + self.dx * dt
        self.y = self.y + self.dy * dt

        -- update engine camera with new values
        camera.set(self.x, self.y, self.size)
    end,

    render = function(self)
        -- don't draw the focus box if it doesn't exist yet
        if self.focus_box == nil then
            return
        end

        -- only render on debug
        if not love.keyboard.isDown('p') then
            return
        end

        -- draw focus box boundaries in green
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.line(self.focus_box.left, self.focus_box.top, self.focus_box.right, self.focus_box.top)
        love.graphics.line(self.focus_box.right, self.focus_box.top, self.focus_box.right, self.focus_box.bottom)
        love.graphics.line(self.focus_box.left, self.focus_box.bottom, self.focus_box.right, self.focus_box.bottom)
        love.graphics.line(self.focus_box.left, self.focus_box.top, self.focus_box.left, self.focus_box.bottom)
    end
}
