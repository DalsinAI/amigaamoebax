# Host test helper: decode a PNG (8-bit, not interlaced) with zlib alone and
# print width, height and the RGBA bytes' sum and hash, like png-dump.c.
# Copyright (c) 2026 AmiCradle Team. GPL 2 or later, like Amoebax.
import struct, sys, zlib

def decode(path):
    d = open(path, 'rb').read()
    assert d[:8] == b'\x89PNG\r\n\x1a\n'
    p, idat, plte, trns = 8, b'', None, None
    while p < len(d):
        n, t = struct.unpack('>I4s', d[p:p + 8])
        body = d[p + 8:p + 8 + n]
        if t == b'IHDR':
            w, h, depth, ct = struct.unpack('>IIBB', body[:10])
        elif t == b'IDAT':
            idat += body
        elif t == b'PLTE':
            plte = body
        elif t == b'tRNS':
            trns = body
        p += 12 + n
    assert depth == 8
    bpp = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ct]
    raw = zlib.decompress(idat)
    stride = w * bpp
    rows, prev, o = [], bytearray(stride), 0
    for _ in range(h):
        f = raw[o]; line = bytearray(raw[o + 1:o + 1 + stride]); o += 1 + stride
        for i in range(stride):
            a = line[i - bpp] if i >= bpp else 0
            b = prev[i]
            c = prev[i - bpp] if i >= bpp else 0
            if f == 1: line[i] = (line[i] + a) & 255
            elif f == 2: line[i] = (line[i] + b) & 255
            elif f == 3: line[i] = (line[i] + (a + b) // 2) & 255
            elif f == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 255
        rows.append(line); prev = line
    out = bytearray()
    for line in rows:
        for i in range(w):
            px = line[i * bpp:(i + 1) * bpp]
            if ct == 6: out += px
            elif ct == 2: out += px + b'\xff'
            elif ct == 0: out += bytes([px[0]] * 3) + b'\xff'
            elif ct == 4: out += bytes([px[0]] * 3) + px[1:2]
            else:
                k = px[0]
                al = trns[k] if trns and k < len(trns) else 255
                out += plte[k * 3:k * 3 + 3] + bytes([al])
    return w, h, out

for path in sys.argv[1:]:
    w, h, out = decode(path)
    s, x = sum(out), 0
    for v in out:
        x = (x * 31 + v) & 0xffffffff
    print(w, h, s, x)
