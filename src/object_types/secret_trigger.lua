--- Secret trigger object type.
-- Animates a layer alpha when overlapped with the player object.
-- Expects 'target_layer' property with layer name to fade.

local log    = require 'log'
local map    = require 'map'
local object = require 'object'
local util   = require 'util'

return {
    init = function(this)
        -- Configuration.
        this.target_alpha   = this.target_alpha or 0.5
        this.fade_out_speed = this.fade_out_speed or 2
        this.fade_in_speed  = this.fade_in_speed or 1.5

        -- State.
        this.intersect = 1

        -- Verify target layer.
        this.target_layer_ref = map.find_layer(this.target_layer or 'MISSING')

        if not this.target_layer_ref then
            log.error('Invalid target_layer %s for secret trigger!', this.target_layer)
            object.destroy(this)
        end

        -- The following is a mega hack but it will work.
        -- In the future maybe some subsystem can be introduced to manage per-layer state.

        -- Decide on a single trigger to manage the alpha.
        if this.target_layer_ref.secret_control then
            table.insert(this.target_layer_ref.secret_triggers, this)
        else
            this.target_layer_ref.secret_control = this
            this.target_layer_ref.secret_triggers = { this }
        end
    end,

    update = function(this, dt)
        -- Locate the player object.
        this.player = this.player or map.find_object('player')

        -- Don't proceed if there's no player.
        if not this.player then
            return
        end

        this.intersect = util.aabb(this, this.player)

        -- Only allow the control trigger to modify the target layer alpha.
        -- There is no guarantee that the other triggers are updated before the control-
        -- this means that the intersection test may be a frame behind. There's not
        -- much we can do about this without introducing a new post-frame event.

        if this.target_layer_ref.secret_control == this then
            -- Check if at least one controlling trigger is colliding.
            local colliding = false

            for _, v in ipairs(this.target_layer_ref.secret_triggers) do
                if v.intersect then
                    colliding = true
                    break
                end
            end

            local a = this.target_layer_ref.alpha_override or 1

            -- Apply alpha animation.
            if colliding then
                a = math.max(a - dt * this.fade_out_speed, this.target_alpha)
            else
                a = math.min(a + dt * this.fade_in_speed, 1)
            end

            this.target_layer_ref.alpha_override = a
        end
    end
}
