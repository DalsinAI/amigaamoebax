Amoebax for GFOS
================

A port of Amoebax 0.2.2, Emma's Software's match-3 versus puzzle game
(https://emma-soft.com/games/amoebax), from carstene1ns's SDL 2 version
(https://github.com/carstene1ns/amoebax-sdl2 at commit
68cbfba133ba47f202686f9e6f9e23944070666d), for GFOS: AmigaOS 3.2 with
GFOpenUp, on a 68040 or 68060 with an FPU, on GFOpenUp's SDL 2.

Drop pairs of amoebas into your grid, line up four of a colour to burst
them, and chain bursts to fill your opponent's grid with garbage. Play Kim
or Tom against six creatures, train alone, or hold a tournament for up to
four players.

Status: built in Cradle's os32-gcc16-open6 stove; not yet run in a lab.


What you need
-------------

- GFOS: AmigaOS 3.2 with GFOpenUp and its GFOpenGPU part, which installs
  LIBS:GFOpenGPU/SDL2.module and SDL2_mixer.module (the Ogg Vorbis music).
- A 68040 or 68060 with an FPU (not an LC040 or EC040), an RTG screen (or
  the AmiCradle lab), and about 12 MB of free memory: the pictures are
  drawn for 1280 x 960 and scaled to the window when they load.


Installing
----------

The release is a GFOpenUp part:

    GFOpenUpTool INSTALL Parts/Amoebax

puts the Amoebax drawer in SYS:Games. GFOpenUpTool REMOVE Parts/Amoebax
takes it out again. Double-click Amoebax, or from a Shell:

    cd SYS:Games/Amoebax
    Amoebax [-f | -w] [--disable-sound]

-f runs on a screen of its own, -w in a window. The window is 800 x 600;
the Options menu changes it and the keys. The settings and the high
scores are kept in the drawer's User drawer (made the first time it runs).


Playing
-------

The player on the right moves the falling pair with Left and Right, turns
it with Up (Right Ctrl the other way) and drops it faster with Down; the
player on the left uses A, D, W, Left Ctrl and S. Esc pauses. The keys and
the joysticks are set in Options, Controls.


Building
--------

    STOVE=/path/to/os32-gcc16-open6 OUT=out ./build-amiga.sh

or, in Cradle, stove_build with the os32-gcc16-open6 stove and target "."
(build-amiga.sh). It fetches Amoebax at the commit amoebax.lock pins, puts
patches/ on it, builds with the stove's SDL 2 and SDL2_mixer link stubs and
writes OUT/Parts/Amoebax (the part: its Part file, Games/Amoebax.info and
the Games/Amoebax drawer) and OUT/unpacked/Games (the same drawer, for a
lab copy). make -C tests test runs the host tests: the Part file, and that
every patch applies and every upstream source file is built.


What was changed
----------------

- patches/0001: the settings file (options.conf) goes to PROGDIR:User
  instead of $XDG_CONFIG_HOME/amoebax; amiga/amiga_start.c makes that
  drawer before main() and sets a 256 KB stack.
- patches/0002: <sstream> before <unistd.h> in File.cxx, and <ctime> in
  System.cxx, for the stove's C++ headers.
- The pictures, fonts, music and sounds are read from PROGDIR:data
  (DATADIR at build time).
- The icons (amiga/icons) are GlowIcons made with amicradle's
  scripts/ports/port_icons.py from upstream's own icon.


Licences
--------

Amoebax's code is GPL 2 or later (LICENSE, COPYING.txt in the drawer); its
pictures, music and sounds are under the Free Art License (Licences.txt in
the drawer). The Amiga files here are The AmiCradle Team's, under the GPL 2
or later like the game.

Designed, tested and delivered by The AmiCradle Team.
