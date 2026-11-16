#!/bin/sh
# Builds Amoebax for GFOS (AmigaOS 3.2.3 with GFOpenUp, on the GFOpenKick ROM
# or a Kickstart) with a stove: 68040 with its FPU (GFOpenGPU's SDL 2 kit is
# hard float), on the stove's SDL 2 and SDL2_mixer (GFOpenGPU's link stubs).
#   STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh
# Amoebax is fetched at the commit amoebax.lock gives, with patches/ on it;
# nothing third-party is kept here.
# OUT gets Parts/Amoebax: a GFOpenUp part (its Part file, the Amoebax drawer
# for SYS:Games and its icon; it needs the GFOpenGPU part, whose SDL2.module
# and SDL2_mixer.module draw and play it), installed with
#   GFOpenUpTool INSTALL Parts/Amoebax
# and unpacked/Games, the same drawer for a lab copy.
# Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like Amoebax.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/amoebax.lock"
STOVE=${STOVE:-"$HOME/AmiCradle/kitchen/stoves/os32-gcc16-open6"}
if [ -x "$STOVE/prefix/bin/m68k-amigaos-gcc" ]; then TC="$STOVE/prefix"; else TC="$STOVE"; fi
# outside the checkout: Cradle cleans it (git clean -ffdx) before every job
WORK="${WORK:-$HOME/.cache/amigaamoebax/build}"; OUT="${OUT:-$WORK/out}"; JOBS=${JOBS:-8}
PATH="$TC/bin:$PATH"; export PATH
mkdir -p "$WORK" "$OUT"; OUT=$(cd "$OUT" && pwd)
t0=$(date +%s)

# --- Amoebax at its pinned commit, with patches/ ------------------------------
SRC="$WORK/amoebax"
PSUM=$(cat "$HERE"/patches/*.patch | sha256sum | cut -c1-16)
if [ "$(cat "$SRC/.patched" 2>/dev/null)" != "$AMX_COMMIT-$PSUM" ]; then
    rm -rf "$SRC"; mkdir -p "$SRC"
    git -C "$SRC" init -q
    git -C "$SRC" fetch -q --depth 1 "$AMX_GIT" "$AMX_COMMIT"
    git -C "$SRC" checkout -q FETCH_HEAD
    [ "$(git -C "$SRC" rev-parse HEAD)" = "$AMX_COMMIT" ] || { echo "commit mismatch"; exit 1; }
    for p in "$HERE"/patches/*.patch; do
        patch -s -d "$SRC" -p1 < "$p" || { echo "patch failed: $p"; exit 1; }
    done
    echo "$AMX_COMMIT-$PSUM" > "$SRC/.patched"
    rm -rf "$WORK/obj"
fi

# --- SDL 2 from the stove's SDK -------------------------------------------------
SDK="$TC/m68k-amigaos"
for f in include/SDL2/SDL.h include/SDL2/SDL_mixer.h lib/libSDL2.a lib/libSDL2_mixer.a; do
    [ -f "$SDK/$f" ] || { echo "the stove has no $f"; exit 2; }
done

# --- one Makefile ---------------------------------------------------------------
# Every src/*.cxx but the Windows and macOS options (tests/test-patches.sh
# checks this list against upstream's tree).
SRCS="AIPlayer.cxx AIPlayerFactory.cxx AdvancedAIPlayer.cxx Amoeba.cxx AnticipatoryAIPlayer.cxx ChainLabel.cxx CongratulationsState.cxx ControlSetupState.cxx CreditsState.cxx DemoState.cxx DumbAIPlayer.cxx FadeInState.cxx FadeOutState.cxx File.cxx Font.cxx FrameManager.cxx Grid.cxx GridStatus.cxx HighScoreState.cxx HumanPlayer.cxx Joystick.cxx MainMenuState.cxx Music.cxx NewHighScoreState.cxx NormalSetupState.cxx NormalState.cxx Options.cxx OptionsMenuState.cxx PairGenerator.cxx PauseState.cxx SimpleAIPlayer.cxx Sound.cxx Surface.cxx System.cxx TournamentMenuState.cxx TournamentSetupState.cxx TournamentState.cxx TrainingState.cxx TryAgainState.cxx TwoComputerPlayersState.cxx TwoPlayersState.cxx VersusState.cxx VideoErrorState.cxx main.cxx"
# -fno-tree-loop-distribute-patterns: GCC 16's loop miscompile (the kit's
# sdl2-config gives it too).
CF="-noixemul -m68040 -m68881 -O2 -fomit-frame-pointer -fno-tree-loop-distribute-patterns -DNDEBUG"
DEFS="-DDATADIR=\\\"PROGDIR:data\\\" -DPACKAGE_NAME=\\\"Amoebax\\\" -DPACKAGE_STRING=\\\"Amoebax-$AMX_VERSION\\\" -DPACKAGE_BUGREPORT=\\\"https://github.com/DalsinAI/amigaamoebax/issues\\\""
O="$WORK/obj"; mkdir -p "$O"
M="$O/Makefile"
{
    echo "CXXF = $CF -std=gnu++11 -I$SDK/include/SDL2 -I$SRC/src -I$SRC/src/ext $DEFS"
    A=""
    for f in $SRCS; do o="${f%.cxx}.o"; A="$A $o"; printf '%s: %s\n\tm68k-amigaos-g++ $(CXXF) -MMD -c $< -o $@\n' "$o" "$SRC/src/$f"; done
    printf 'UnixOptions.o: %s\n\tm68k-amigaos-g++ $(CXXF) -MMD -c $< -o $@\n' "$SRC/src/unix/UnixOptions.cxx"
    printf 'cute_png.o: %s\n\tm68k-amigaos-g++ $(CXXF) -MMD -c $< -o $@\n' "$SRC/src/ext/cute_png.cpp"
    printf 'amiga_start.o: %s\n\tm68k-amigaos-gcc %s -c $< -o $@\n' "$HERE/amiga/amiga_start.c" "$CF"
    echo "OBJS =$A UnixOptions.o cute_png.o amiga_start.o"
    echo "all: \$(OBJS)"
    echo "-include *.d"
} > "$M"
set +e
(cd "$O" && nice -n 19 make -k -j"$JOBS" all > make.log 2>&1)
rc=$?
set -e
grep -E 'error|Error' "$O/make.log" | head -60
[ "$rc" = 0 ] || { tail -20 "$O/make.log"; exit "$rc"; }
echo "compile: $(( $(date +%s) - t0 )) s"

# --- the link -------------------------------------------------------------------
OBJS=$(cd "$O" && for f in $(sed -n 's/^OBJS =//p' Makefile); do echo "$O/$f"; done)
# shellcheck disable=SC2086
m68k-amigaos-g++ -noixemul -m68040 -m68881 -o "$O/Amoebax.debug" $OBJS \
    -L"$SDK/lib" -lSDL2_mixer -lSDL2 -lm -lpthread -latomic > "$O/link.log" 2>&1 || { head -60 "$O/link.log"; exit 1; }

# --- the GFOpenUp part: Parts/Amoebax --------------------------------------------
P="$OUT/Parts/Amoebax"; rm -rf "$P"; D="$P/Games/Amoebax"; mkdir -p "$D"
m68k-amigaos-strip -o "$D/Amoebax" "$O/Amoebax.debug"
mkdir -p "$D/data"
for d in fonts graphics music sfx; do cp -R "$SRC/data/$d" "$D/data/"; done
cp "$HERE/README.md" "$D/ReadMe"
cp "$SRC/COPYING.GPL" "$D/COPYING.txt"
cp "$SRC/COPYING.LAL" "$D/Licences.txt"
I="$HERE/amiga/icons"
cp "$I/Amoebax.info" "$D/Amoebax.info"
for f in ReadMe COPYING.txt Licences.txt; do cp "$I/ReadMe.info" "$D/$f.info"; done
cp "$I/Data.info" "$D/data.info"
cp "$I/Amoebax-drawer.info" "$P/Games/Amoebax.info"
sh "$HERE/scripts/write-part.sh" "$P" "$AMX_VERSION"
rm -rf "$OUT/unpacked"; mkdir -p "$OUT/unpacked"; cp -R "$P/Games" "$OUT/unpacked/"
ls -l "$D/Amoebax"
echo "part: $(grep -c '^copy' "$P/Part") files, $(du -sk "$P" | cut -f1) KB"
echo "total: $(( $(date +%s) - t0 )) s"
