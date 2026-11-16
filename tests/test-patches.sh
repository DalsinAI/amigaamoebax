#!/bin/sh
# Host test: every patch in patches/ applies to Amoebax at the commit
# amoebax.lock pins, and the options go to PROGDIR:User on AmigaOS.
# Needs git and the network (GitHub). Copyright (c) 2026 AmiCradle Team.
# GPL 2 or later, like Amoebax.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../amoebax.lock"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
git -C "$T" init -q
git -C "$T" fetch -q --depth 1 "$AMX_GIT" "$AMX_COMMIT"
git -C "$T" checkout -q FETCH_HEAD
for p in "$HERE"/../patches/*.patch; do
    patch -s -d "$T" -p1 --dry-run < "$p" >/dev/null || { echo "FAIL: $p does not apply"; exit 1; }
    patch -s -d "$T" -p1 < "$p"
done
grep -q 'PROGDIR:User' "$T/src/unix/UnixOptions.cxx" || { echo "FAIL: options not in PROGDIR:User"; exit 1; }
# every source file the build compiles is in the tree
for f in $(sed -n 's/^SRCS="\(.*\)"$/\1/p' "$HERE/../build-amiga.sh"); do
    [ -f "$T/src/$f" ] || { echo "FAIL: no src/$f upstream"; exit 1; }
done
# and none upstream is left out (other than the Windows and macOS options)
for f in $(cd "$T/src" && ls *.cxx); do
    sed -n 's/^SRCS="\(.*\)"$/\1/p' "$HERE/../build-amiga.sh" | tr ' ' '\n' | grep -qxF "$f" || { echo "FAIL: src/$f not built"; exit 1; }
done
echo "patches: all apply, sources match"
