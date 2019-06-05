### contributing

To contribute to the repository, any pull requests must first pass CI.
To locally test if your branch will pass, you will need to install `luacheck` on your system.

Installing `luacheck` is very easy. First, ensure you have Lua's package manager `luarocks` installed.

Then, install `luacheck` with the following:

```BASH
$ sudo luarocks install luacheck
```

Once `luacheck` is installed, run it on the source code with the following:

```BASH
$ luacheck src
```

The linter will output warnings and problems with the code.
To pass the CI test, there need to be *no* warnings present.
