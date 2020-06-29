--- Main menu object type.

local camera  = require 'camera'

return {
    init = function(this)
        this.scrollspeed = 32
        this.focus_x = 0

        camera.center(0, 0)
        camera.set_focus_follow_enabled(false)
    end,

    update = function(this, dt)
        -- Slowly scroll camera.
        this.focus_x = this.focus_x + dt * this.scrollspeed
        camera.center(this.focus_x, 0)
    end,
}
