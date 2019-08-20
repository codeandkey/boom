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
        this.current_alpha = 1

        -- Verify target layer.
        this.target_layer_ref = map.find_layer(this.target_layer or 'MISSING')

        if not this.target_layer_ref then
            log.error('Invalid target_layer %s for secret trigger!', this.target_layer)
            object.destroy(this)
        end
    end,

    update = function(this, dt)
        -- Locate the player object.
        this.player = this.player or map.find_object('player')

        -- Don't proceed if there's no player.
        if not this.player then
            return
        end

        -- Check for collisions and animate target layer alpha.
        if util.aabb(this, this.player) then
            -- Animate towards target alpha.
            this.current_alpha = math.max(this.target_alpha, this.current_alpha - dt * this.fade_out_speed)
        else
            -- Animate towards normal alpha.
            this.current_alpha = math.min(1, this.current_alpha + dt * this.fade_in_speed)
        end

        -- Set the tile layer's alpha override.
        this.target_layer_ref.alpha_override = this.current_alpha
    end
}
