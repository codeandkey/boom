## sequences

All sequence files should return a group of potential sequences in an ordered list.
When a sequence is read via `fs.read_sequence` one of the sequences is chosen to be executed.

Every sequence is an ordered list of lines. Every line must have an 'actor' and a 'text'.
The 'actor' should refer to the name of the object which will say the line.
The 'text' will define what the actor says.

Example sequence:
```
return {
    {
        {
            actor = 'my_actor',
            line  = 'This is the first line of the first possible sequence.',
        },
        {
            actor = 'my_actor2',
            line  = 'This is the second line of the first possible sequence.',
        },
    },

    {
        {
            actor = 'other_actor',
            line  = 'This line is in a second potential sequence.',
        },
    },
}
```
