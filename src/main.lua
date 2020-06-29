--[[
    main.lua
    entry point and mainloop
]]--

local camera  = require 'camera'
local dialog  = require 'dialog'
local event   = require 'event'
local input   = require 'input'
local fs      = require 'fs'
local hud     = require 'hud'
local log     = require 'log'
local map     = require 'map'
local options = require 'options'
local post    = require 'post'

local enable_debug    = false
local debug_font      = nil
local last_delta      = 0
local delta_graph     = {}
local delta_graph_len = 128
local delta_graph_ind = 0

function love.load(arg)
    hud.init()

    -- Initialize options and video mode.
    if not options.load() then
        log.error('Could not load a valid video mode. Exiting..')
        love.event.quit(1)
    end

    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- Apply debug mode if requested.
    for _, v in ipairs(arg) do
        if v == '--debug' or v == '-d' then
            enable_debug = true
            debug_font = fs.read_font('pixeled.ttf', 8)
            log.info('Running in debug mode.')
        else
            log.warn('Invalid command-line argument %s!', v)
        end
    end

    map.load('main_menu')
    log.info('Finished loading.')
end

function love.resize()
    local w, h, flags = love.window.getMode()

    log.debug('Using new video mode: %d by %d, fullscreen %s (%s), vsync %s, msaa %s',
              w, h, flags.fullscreen, flags.fullscreentype, tostring(flags.vsync), flags.msaa)

    camera.rescale(w, h)
end

function love.keypressed(key)
    -- Translate key to the bound input (if there is one).
    local inp = input.translate(key)

    if inp ~= nil then
        event.push('inputdown', inp)
    end
end

function love.keyreleased(key)
    local inp = input.translate(key)

    if inp ~= nil then
        event.push('inputup', inp)
    end
end

function love.quit()
    map.unload()
end

function love.update(dt)
    -- Process all pending game events.
    event.run()

    map.update(dt)
    camera.update(dt)
    dialog.update(dt)

    if enable_debug then
        last_delta = dt
        delta_graph_ind = delta_graph_ind % delta_graph_len
        delta_graph_ind = delta_graph_ind + 1
        delta_graph[delta_graph_ind] = dt
    end
end

function love.draw()
    hud.start()
    post.begin_frame()
    camera.apply()
    map.render()
    camera.unapply()
    dialog.render()
    hud.render()
    post.end_frame()

    if enable_debug then
        -- Render some debug information.
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(debug_font)
        love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
        love.graphics.print('LAST DELTA: ' .. string.format('%.2f', last_delta * 1000) .. ' ms', 10, 30)
        love.graphics.print('MAP: ' .. map.get_current_name() or '(none)', 10, 50)

        -- Draw delta time graph.
        local left = 180
        local bottom = 40
        local height = 256
        local last = bottom

        for i=1,delta_graph_len do
            local v = delta_graph[i] or 0
            local dist = delta_graph_ind - i
            if dist < 0 then
                dist = delta_graph_len - i + delta_graph_ind
            end
            love.graphics.setColor(1, 1, 1, 1 - dist / delta_graph_len)
            love.graphics.line(left + i, bottom - (v * height), left + (i - 1), last)
            last = bottom - (v * height)
        end
    end
end
