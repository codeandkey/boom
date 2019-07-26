# Boom ![nade](src/assets/sprites/16x16_nade.png "boom")

## Boom?

Boom is an open-source platformer designed as a prototype for creating a
finished product. The goal of this project is to finish the game in it's
entirety, complete with a central mechanic and a compact design that also
provides an entertaining experience.

## Boom.

Before running the game you'll need to install the Love2d engine. Love is
available on the official repositories for most linux distributions.
If you need help or don't know how to install love2d for your system you can
check out the [Love2d website](https://love2d.org).

Boom can be run either by executing the `boom` executable

```BASH
./boom
```

or by running the command

```BASH
love src
```

from the root directory.

## Boom. Maps.

To design maps for Boom you will need to get the [Tiled](https://www.mapeditor.org/) map editor.
In the `src/assets` directory you will find Boom's object types and tilesets
which can be imported into the map editor.

Some useful object types:
- `player` is the player spawn point.
- `physbox` is a physics object. Requires `type` string parameter.
	- setting `type` to `dynamic` allows interaction with other objects.
	- setting `type` to `static` forces a static object.

- 'npc' is a non-player-character, they can be given Names that will be displayed in-game.
- 'background' denotes an image to be used in parallax for backgrounds
## Boom. Physics.

Boom uses Love2d's builtin physics engine, [Box2D](http://box2d.org/about/).

## Boom. Devs.

<!-- Please forgive my html in markdown for the really pretty table -->

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/quigley-c">
      <img src="https://avatars1.githubusercontent.com/u/35495466?s=460&v=4"
        width=128px>
      <h3><a href="https://github.com/quigley-c">Carson Quigley</a></h3>
      <h4><a href="https://quigleyc.com">quigleyc.com</a><h4>
    </td>
    <td align="center">
      <a href="https://github.com/codeandkey">
      <img src="https://avatars1.githubusercontent.com/u/3630356?s=460&v=4"
        width=128px>
      <h3><a href="https://github.com/codeandkey">Justin S</a></h3>
      <h4><a href="https://codeandkey.github.io">codeandkey.github.io</a><h4>
    </td>
  </tr>
</table>
