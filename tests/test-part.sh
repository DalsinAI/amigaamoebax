#!/bin/sh
# Host test for scripts/write-part.sh: the Part file GFOpenUpTool reads.
# Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like Amoebax.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/Games/Amoebax/data/graphics" "$T/Games/Amoebax/data/music"
: > "$T/Games/Amoebax/Amoebax"; : > "$T/Games/Amoebax.info"
: > "$T/Games/Amoebax/data/graphics/Kim.png"; : > "$T/Games/Amoebax/data/music/menu.ogg"
sh "$HERE/../scripts/write-part.sh" "$T" 0.2.2
fail=0
expect() { grep -qxF "$1" "$T/Part" || { echo "FAIL: no line: $1"; fail=1; }; }
expect 'part Amoebax 0.2.2'
expect 'needs 68040'
expect 'needs part GFOpenGPU'
expect 'copy "Games/Amoebax.info" "SYS:Games/Amoebax.info"'
expect 'copy "Games/Amoebax/Amoebax" "SYS:Games/Amoebax/Amoebax"'
expect 'copy "Games/Amoebax/data/graphics/Kim.png" "SYS:Games/Amoebax/data/graphics/Kim.png"'
expect 'copy "Games/Amoebax/data/music/menu.ogg" "SYS:Games/Amoebax/data/music/menu.ogg"'
[ "$(head -1 "$T/Part")" = 'part Amoebax 0.2.2' ] || { echo "FAIL: first line"; fail=1; }
[ "$(grep -c '^copy' "$T/Part")" = 4 ] || { echo "FAIL: copy count (the Part file itself must not be listed)"; fail=1; }
sh "$HERE/../scripts/write-part.sh" "$T" 0.2.2   # a second run: same file
[ "$(grep -c '^copy' "$T/Part")" = 4 ] || { echo "FAIL: second run lists the Part file"; fail=1; }
[ $fail = 0 ] && echo "Part file: all checks passed"
exit $fail
