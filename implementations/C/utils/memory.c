#include "memory.h"

#include <stdlib.h>
#include <string.h>

/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   Core Memory Primitives
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
void memCopy(void* restrict dst, const void* restrict src, const usize size) {
    if (!size || dst == src) return;

#if defined(__GNUC__) || defined(__clang__)
    if (__builtin_constant_p(size) && size == 1) {
        *(u8*)dst = *(const u8*)src;
        return;
    }
#endif

    __builtin_memcpy(dst, src, size);
}

void memMove(void* dst, const void* src, const usize size) {
    if (!size || dst == src) return;
    __builtin_memmove(dst, src, size);
}

void memSwap(void* a, void* b, usize size) {
    if (!size || a == b) return;

    u8* p1 = (u8*)a;
    u8* p2 = (u8*)b;

    // Use the largest natural word size possible
#if ARCH_is64BIT
    while (size >= 8) {
        const u64 tmp = *(u64*)p1;
        *(u64*)p1 = *(u64*)p2;
        *(u64*)p2 = tmp;
        p1 += 8; p2 += 8; size -= 8;
    }
#elif ARCH_is32BIT
    while (size >= 4) {
        const u32 tmp = *(u32*)p1;
        *(u32*)p1 = *(u32*)p2;
        *(u32*)p2 = tmp;
        p1 += 4; p2 += 4; size -= 4;
    }
#endif

    // Swap remaining bytes
    while (size--) {
        const u8 tmp = *p1;
        *p1++ = *p2;
        *p2++ = tmp;
    }
}

void memSet(void* dst, const u8 value, const usize size) {
    if (!size) return;
    __builtin_memset(dst, value, size);
}

i32 memCmp(const void* restrict a, const void* restrict b, const usize size) {
    if (a == b) return 0;
    return memcmp(a, b, size);
}


/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   Allocation Helpers
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

void* memClone(const void* src, const usize size) {
    if (!src || !size) return NULL;

    void* dst = malloc(size);
    if (!dst) return NULL;

    __builtin_memcpy(dst, src, size);
    return dst;
}

void* memCloneWith(const void* src, const usize size, void* (*alloc)(usize)) {
    if (!src || !size || !alloc) return NULL;

    void* dst = alloc(size);
    if (!dst) return NULL;

    __builtin_memcpy(dst, src, size);
    return dst;
}

void memTransfer(void* dst, void* src, const usize size) {
    if (!size || dst == src) return;

    __builtin_memmove(dst, src, size);
    __builtin_memset(src, 0, size);
}


/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   Bit-Level Memory Operations
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

void memBitShl(void* data, usize bits, const usize size) {
    if (!size) return;

    bits %= (size * 8);
    if (!bits) return;

    u8* p = (u8*)data;

    const usize byteShift = bits >> 3;
    const usize bitShift  = bits & 7;

    if (byteShift) {
        memMove(p, p + byteShift, size - byteShift);
        memSet(p + size - byteShift, 0, byteShift);
    }

    if (bitShift) {
        for (usize i = 0; i < size - 1; ++i) {
            p[i] = (u8)((p[i] << bitShift) |
                        (p[i + 1] >> (8 - bitShift)));
        }
        p[size - 1] <<= bitShift;
    }
}

void memBitShr(void* data, usize bits, const usize size) {
    if (!size) return;

    bits %= (size * 8);
    if (!bits) return;

    u8* p = (u8*)data;

    const usize byteShift = bits >> 3;
    const usize bitShift  = bits & 7;

    if (byteShift) {
        memMove(p + byteShift, p, size - byteShift);
        memSet(p, 0, byteShift);
    }

    if (bitShift) {
        for (usize i = size - 1; i > 0; --i) {
            p[i] = (u8)((p[i] >> bitShift) |
                        (p[i - 1] << (8 - bitShift)));
        }
        p[0] >>= bitShift;
    }
}

void memBitRol(void* data, usize rotate, const usize size) {
    if (!size) return;

    rotate %= (size * 8);
    if (!rotate) return;

    u8* p = (u8*)data;

    u8 stackBuf[256];
    u8* tmp = (size <= sizeof(stackBuf))
        ? stackBuf
        : (u8*)malloc(size);

    if (!tmp) return;

    __builtin_memcpy(tmp, p, size);

    memBitShl(p, rotate, size);
    memBitShr(tmp, (size * 8) - rotate, size);

    for (usize i = 0; i < size; ++i)
        p[i] |= tmp[i];

    if (tmp != stackBuf)
        free(tmp);
}

void memBitRor(void* data, usize rotate, const usize size) {
    if (!size) return;

    rotate %= (size * 8);
    if (!rotate) return;

    u8* p = (u8*)data;

    u8 stackBuf[256];
    u8* tmp = (size <= sizeof(stackBuf))
        ? stackBuf
        : (u8*)malloc(size);

    if (!tmp) return;

    __builtin_memcpy(tmp, p, size);

    memBitShr(p, rotate, size);
    memBitShl(tmp, (size * 8) - rotate, size);

    for (usize i = 0; i < size; ++i)
        p[i] |= tmp[i];

    if (tmp != stackBuf)
        free(tmp);
}
