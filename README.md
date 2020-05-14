# Boom ![nade](src/assets/sprites/obj/16x16_nade.png "boom")

## Boom?

Boom is an open-source platformer codeandkey and myself (quigley-c) began with
the goal of finishing a project together. The goal of this project is to
finish the game in it's entirety, complete with a central mechanic and a
compact design that also provides an entertaining experience.

## HTML Documentation

The documentation can be viewed by opening `index.html` inside `doc` with your
favorite web browser.

If for some reason you can't view the doc you can compile it yourself. 
To compole the documentation you'll need to install `ldoc` and compile with the
build script. If you don't have luarocks you can install it on most linux
distributions with `apt`. Once luarocks has been installed you can install
`ldoc`.

```BASH
apt install luarocks

luarocks install ldoc
```

## Quickstart

Before running the game you'll need to install the Love2d engine. Love is
available on the official repositories for most linux distributions.
If you need help or don't know how to install love2d for your system you can
check out the [Love2d website](https://love2d.org). Most linux distributions
can install love with the command: 

```BASH
apt install love
```
## Boom. 

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
In the `src/object_types` directory you will find Boom's object types that can be used in the editor.

Some useful object types:
- `player` is the player spawn point.
- `npc` is a passive non-player-character.
- `load_trigger` will prompt the player to transition to another map
	- `interactable` makes the trigger usable by the player
	- `destination` points to another map
	- `entry_point` points to the load trigger the other map
- `background` draws a background with optional parallax movement.
    - `parallax_x` denotes the horizontal parallax factor. Higher values will
		make motion slower. `1` will lock the background to the camera.
    - `parallax_y` denotes the vertical parllax factor.
- `nade`, `explosion`, and `gib` are types used at runtime and should not be placed in the map.

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
