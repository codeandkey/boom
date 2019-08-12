--- Destructible crate object type.
-- Can be broken into pieces with explosions.

local map          = require 'map'
local object       = require 'object'
local object_group = require 'object_group'
local sprite       = require 'sprite'

return {
    init = function(this)
        -- Overwrite dimensions.
        this.w = 32
        this.h = 32

        -- Initialize sprite.
        this.image = sprite.create('32x32_crate.png')

        -- Initialize physics state.
        this.shape = love.physics.newRectangleShape(this.w, this.h)
        this.body = love.physics.newBody(map.get_physics_world(), this.x + this.w / 2, this.y + this.h / 2, 'dynamic')
        this.fixture = love.physics.newFixture(this.body, this.shape)
    end,

    destroy = function(this)
        -- Physics cleanup.
        this.body:destroy()
    end,

    explode = function(this, _, _, _)
        -- Break the crate into crate gibs.
    
        -- 4 perimeter frame pieces
        object_group.create_object(this.__layer, 'gib', {
            spr_name = '32x4_crate_frame.png',
            x = this.x,
            y = this.y,
        })

        object_group.create_object(this.__layer, 'gib', {
            spr_name = '32x4_crate_frame.png',
            x = this.x - 16,
            y = this.y + 14,
            angle = math.rad(270),
        })

        object_group.create_object(this.__layer, 'gib', {
            spr_name = '32x4_crate_frame.png',
            x = this.x,
            y = this.y + 28,
            angle = math.rad(180),
        })

        object_group.create_object(this.__layer, 'gib', {
            spr_name = '32x4_crate_frame.png',
            x = this.x + 16,
            y = this.y + 14,
            angle = math.rad(90),
        })

        -- 7 internal boards.
        for i=0,6 do
            object_group.create_object(this.__layer, 'gib', {
                spr_name = '28x4_crate_board.png',
                x = this.x + 2,
                y = this.y + 2 + 4 * i,
            })
        end

        object.destroy(this)
    end,

    render = function(this)
        -- Get physbox location.
        this.angle = this.body:getAngle()
        this.x = this.body:getX() - this.w / 2
        this.y = this.body:getY() - this.h / 2

        -- Draw crate sprite over physbox.
        love.graphics.setColor(1, 1, 1, 1)
        sprite.render(this.image, this.x, this.y, this.angle)
    end,
}
