/* Host test helper: decode a PNG with Amoebax's own cute_png (patched) and
 * print width, height and the RGBA bytes' sum and xor, for test-png.sh to
 * compare with png-ref.py. Copyright (c) 2026 AmiCradle Team. GPL 2 or
 * later, like Amoebax. */
#define CUTE_PNG_IMPLEMENTATION
#include "cute_png.h"
#include <stdio.h>

int main(int argc, char **argv)
{
    for (int i = 1; i < argc; i++) {
        cp_image_t img = cp_load_png(argv[i]);
        unsigned long sum = 0, x = 0;
        const unsigned char *p = (const unsigned char *)img.pix;
        if (!img.pix) {
            printf("%s: %s\n", argv[i], cp_error_reason);
            return 1;
        }
        for (long n = 0; n < (long)img.w * img.h * 4; n++) {
            sum += p[n];
            x = (x * 31 + p[n]) & 0xffffffffUL;
        }
        printf("%d %d %lu %lu\n", img.w, img.h, sum, x);
        cp_free_png(&img);
    }
    return 0;
}
