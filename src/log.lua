--- Logging API.

local log = {
    -- state
    backlog = {},
    backlog_head = 1,

    -- constants
    LEVEL_ERROR = 1,
    LEVEL_INFO  = 2,
    LEVEL_WARN  = 3,
    LEVEL_DEBUG = 4,

    LEVEL_ATTRS = {
        { -- ERROR
            rgba = { 1.0, 0.0, 0.0, 1.0 },
            term = '\027[1;31m',
            pfx = 'ERROR   | ',
        },
        { -- INFO
            rgba = { 0.0, 1.0, 1.0, 1.0 },
            term = '\027[1;36m',
            pfx = 'INFO    | ',
        },
        { -- WARN
            rgba = { 1.0, 1.0, 0.0, 1.0 },
            term = '\027[1;32m',
            pfx = 'WARNING | ',
        },
        { -- DEBUG
            rgba = { 0.0, 1.0, 0.0, 1.0 },
            term = '\027[1;34m',
            pfx = 'DEBUG   | ',
        },
    },

    -- options
    backlog_size = 128,
    verbosity = 4,
}

--- Generic level logger.
-- @param level Log level. Defaults to `log.LEVEL_ERROR` if nil.
-- @param ... Format arguments. Passed to @{string.format}.
function log.level(level, ...)
    -- Ignore levels excluded by verbosity.
    if level > log.verbosity then
        return
    end

    -- Query the level attributes.
    local attrs = log.LEVEL_ATTRS[level]

    -- Write the backlog.
    log.backlog[log.backlog_head] = {
        level = level or log.LEVEL_ERROR,
        content = string.format(...)
    }

    -- Write to the terminal.
    print(attrs.term .. attrs.pfx .. '\027[0;39m' .. log.backlog[log.backlog_head].content)

    -- Increment the head, modulo the backlog size.
    log.backlog_head = log.backlog_head + 1

    if log.backlog_head > log.backlog_size then
        log.backlog_head = 1
    end
end

--- Debug level log message.
-- @param ... Format arguments. Passed to @{string.format}.
function log.debug(...)
    return log.level(log.LEVEL_DEBUG, ...)
end

--- Warning level log message.
-- @param ... Format arguments. Passed to @{string.format}.
function log.warn(...)
    return log.level(log.LEVEL_WARN, ...)
end

--- Info level log message.
-- @param ... Format arguments. Passed to @{string.format}.
function log.info(...)
    return log.level(log.LEVEL_INFO, ...)
end

--- Error level log message.
-- @param ... Format arguments. Passed to @{string.format}.
function log.error(...)
    return log.level(log.LEVEL_ERROR, ...)
end

--- Get the log color for a level.
-- @param level Level to query.
-- @return The appropriate color as a numeric array with 4 elements. (RGBA 0.0-1.0)
function log.level_color(level)
    return log.LEVEL_ATTRS[level].rgba
end

--- Get the ordered backlog.
-- @return The backlog array. Each entry will have the fields _level_ and _content_.
function log.get_backlog()
    local backlog = {}

    for i=log.backlog_head,log.backlog_size do
        local entry = log.backlog[i]

        if entry ~= nil then
            table.insert(backlog, entry)
        end
    end

    for i=1,log.backlog_head-1 do
        local entry = log.backlog[i]

        if entry ~= nil then
            table.insert(backlog, entry)
        end
    end

    return backlog
end

return log
