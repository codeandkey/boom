--- Input mapping subsbystem.

local input = {
    binds = {
        left     = 'left',
        right    = 'right',
        up       = 'up',
        down     = 'down',
        jump     = 'z',
        throw    = 'x',
        ok       = {'z', 'return', 'space'},
        interact = 'c',
    },
    map = {},
}

--- Try an input key.
-- 'cb' is called once with every mapped input.
function input.try(key, cb)
    if input.map[key] then
        for _, v in ipairs(input.map[key]) do
            cb(v)
        end
    end
end

-- Construct inverted binds table.
for k, v in pairs(input.binds) do
    if type(v) == 'string' then
        v = { v }
    end

    for _, key in ipairs(v) do
        if input.map[key] then
            table.insert(input.map[key], k)
        else
            input.map[key] = { k }
        end
    end
end

return input
