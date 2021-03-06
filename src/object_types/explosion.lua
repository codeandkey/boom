--- Explosion object type.

local camera = require 'camera'
local map    = require 'map'
local object = require 'object'
local object_group = require 'object_group'

return {
    init = function(this)
        -- Configuration.
        this.resolution   = this.resolution or 100
        this.radius       = this.radius or 150
        this.object_range = this.object_range or 100
        this.intensity    = this.intensity or 5
        this.num_casts    = this.num_casts or 5 -- number of times rays sent out after init

        -- Look for nearby objects to explode.
        map.foreach_object(function (other_obj)
            if other_obj.x == nil or other_obj.y == nil then
                return
            end

            local dist = math.sqrt(math.pow(other_obj.x - this.x, 2) + math.pow(other_obj.y - this.y, 2))

            if dist < this.object_range then
                other_obj.w = other_obj.w or 32
                other_obj.h = other_obj.h or 32
                other_obj.x = other_obj.x + (other_obj.w/2)
                other_obj.y = other_obj.y - (other_obj.h/2)
                object.call(other_obj,
                            'explode',
                            dist,
                            (other_obj.x - this.x) / dist,
                            (other_obj.y - this.y) / dist, this.radius);
            end
        end)

        -- Create an explosion effect.
        object_group.create_object(this.__layer, 'effect_explosion', {
            x = this.x,
            y = this.y,
            w = 1,
            h = 1,
        })

        -- Shake the camera a little.
        camera.setshake(0.2)
    end,

    update = function(this)
        -- Send out as many casts as needed and then destroy.
        if this.num_casts > 0 then
            -- Shoot out explosion rays into the physics world.
            for i=1,this.resolution do
                local theta = (i / this.resolution) * 3.141 * 2.0

                map.get_physics_world():rayCast(
                    this.x, this.y,
                    this.x + this.radius * math.cos(theta),
                    this.y + this.radius * math.sin(theta),
                    function (fixture, x, y, _, _, fraction)
                        local impulse_vector = {
                            x = x - this.x,
                            y = y - this.y,
                        }

                        local impulse_length = (1.0 - fraction) * this.radius

                        impulse_vector.x = impulse_vector.x * this.intensity / impulse_length
                        impulse_vector.y = impulse_vector.y * this.intensity / impulse_length

                        fixture:getBody():applyLinearImpulse(impulse_vector.x, impulse_vector.y)

                        return 0
                    end
                )
            end

            this.num_casts = this.num_casts - 1
        else
            object.destroy(this)
        end
    end,
}
