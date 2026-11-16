/* The Amiga port's start: the stack, the version string and PROGDIR:User
 * (the settings and the high scores, options.conf), made before main().
 * Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like Amoebax. */
#include <sys/stat.h>

/* A Shell gives 4 KB of stack; SDL 2, the PNG loader and C++ exceptions
 * want more. libnix's startup sets this much up. */
unsigned long __stack = 256 * 1024;
static const char version[] __attribute__((used)) =
    "$VER: Amoebax 0.2.2 (16.11.2026)";

static void __attribute__((constructor)) amiga_user_drawer(void)
{
	mkdir("PROGDIR:User", 0755);
}
