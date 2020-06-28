possibilities = {

    interact1 = {
        {
            actor = 'Merchant',
            text  = 'WHAT IS IT?',
        },
    },

    interact2 = {
        {
            actor = 'Merchant',
            text  = 'I\'M BUSY RIGHT NOW.',
        },
    },
}


return select(math.random(select('#', possibilities)), possibilities)
