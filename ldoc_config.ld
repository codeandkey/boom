--[[
    ldoc configuration
]]--

project = "Boom"
description = "boom documentation"
format = "discount"
pretty = "lxsh"

file = {
    'src',
    exclude = {
        'src/assets',
        'src/examples',
        'src/object_types',
        'src/object_types.lua',
        'src/component_types',
        'src/component_types.lua',
    },
}

examples = {
    'src/examples',
}

topics = {
    'src/topics/Events.md',
}
