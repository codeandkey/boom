--- Test dialog sequence.

return {
    {
        actor = 'player',
        hold  = 1,
        text  = 'HELLO WORLD!',
    },

    1, -- 1 second delay

    {
        actor = 'player',
        hold  = 0.5,
        text  = 'THIS TEXT HAS A SHORTER HOLD.',
    },
}
