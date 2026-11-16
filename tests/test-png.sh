#!/bin/sh
# Host test: Amoebax's cute_png, with patches/ on it, still decodes the
# game's own pictures byte for byte like a plain zlib decoder (png-ref.py),
# and patch 0003 turns each DEFLATE word round on a big-endian CPU (the
# 68k reads them back to front without it, and the game crashed in
# cp_inflate). Needs git, cc, python3 and the network (GitHub).
# Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like Amoebax.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../amoebax.lock"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
git -C "$T" init -q
git -C "$T" fetch -q --depth 1 "$AMX_GIT" "$AMX_COMMIT"
git -C "$T" checkout -q FETCH_HEAD
for p in "$HERE"/../patches/*.patch; do
    patch -s -d "$T" -p1 < "$p"
done
H="$T/src/ext/cute_png.h"
grep -A3 '__ORDER_BIG_ENDIAN__' "$H" | grep -q '__builtin_bswap32(word)' || { echo "FAIL: no big-endian word swap in cute_png.h"; exit 1; }
# The swap sits on the one place DEFLATE words are read.
[ "$(grep -c 's->words\[s->word_index++\]' "$H")" = 1 ] || { echo "FAIL: words read in more than one place"; exit 1; }
cc -O1 -w -I"$T/src/ext" -o "$T/png-dump" "$HERE/png-dump.c"
G="$T/data/graphics"
set -- "$G/menuBackground.png" "$G/amoebax.png" "$T/data/fonts/fontMenu480.png"
for f in "$@"; do
    a=$("$T/png-dump" "$f"); b=$(python3 "$HERE/png-ref.py" "$f")
    [ "$a" = "$b" ] || { echo "FAIL: $(basename "$f"): cute_png '$a', zlib '$b'"; exit 1; }
done
echo "png: $# pictures decode like zlib; big-endian swap in place"
