/* TODO: need testing */

#include "memory.h"
#include "platform.h"

#include <string.h>

#if ARCH_isX86_FAMILY
#   include <immintrin.h>
#endif
#if ARCH_isARM_FAMILY && ARCH_hasNEON
#   include <arm_neon.h>
#endif

void memCopy(void* src, void* dst, usize size) {
    if (!size || src == dst) return;

#if ARCH_isX86_64
    if (size > 256) {
        usize n = size;

        __asm__ __volatile__(
            "rep movsb"
            : "+D"(dst), "+S"(src), "+c"(n)
            :
            : "memory"
        );
        return;
    }
#endif

    if (size >= 128) {
        memcpy(dst, src, size);
        return;
    }

    usize n = size;
    u8* s = (u8*)src;
    u8* d = (u8*)dst;

    while (n >= sizeof(u64)) {
        *(u64*)d = *(u64*)s;
        d += 8; s += 8; n -= 8;
    }
    while (n--) *d++ = *s++;
}

void memSwap(void* memA, void* memB, const usize size) {
    if (!size || memA == memB) return;

    usize n = size;
    u8* a = (u8*)memA;
    u8* b = (u8*)memB;

    while (n >= 8) {
        const u64 t  = *(u64*)a;
        *(u64*)a = *(u64*)b;
        *(u64*)b = t;
        a += 8; b += 8; n -= 8;
    }
    while (n--) {
        const u8 t = *a;
        *a++ = *b;
        *b++ = t;
    }
}

void memMove(void* src, void* dst, const usize size) {
    if (!size || src == dst) return;

    memmove(dst, src, size);
    memset(src, 0, size);
}

i32 memCmp(void* src, void* dst, const usize size) {
    if (src == dst) return 0;

#if ARCH_isX86_FAMILY && ARCH_hasSSE2
    u8* a = (u8*)src;
    u8* b = (u8*)dst;
    usize n = size;

    while (n >= 16) {
        const __m128i v1 = _mm_loadu_si128((__m128i*)a);
        const __m128i v2 = _mm_loadu_si128((__m128i*)b);
        const __m128i cmp = _mm_cmpeq_epi8(v1, v2);
        if (_mm_movemask_epi8(cmp) != 0xFFFF)
            return 1;
        a += 16; b += 16; n -= 16;
    }
    while (n--) if (*a++ != *b++) return 1;
    return 0;
#else
    return memcmp(src, dst, size) != 0;
#endif
}

void memSet(void* src, u8 value, const usize size) {
#if ARCH_isX86_64
    if (size > 128) {
        usize n = size;

        __asm__ __volatile__(
            "rep stosb"
            : "+D"(src), "+c"(n)
            : "a"(value)
            : "memory"
        );
        return;
    }
#endif

    memset(src, value, size);
}

void memShl(void* src, usize shift, const usize size) {
    if (!size) return;
    shift %= (size * 8);
    if (!shift) return;

    u8* p = (u8*)src;

    const usize byteShift = shift >> 3;
    const usize bitShift  = shift & 7;

    if (byteShift)
        memmove(p, p + byteShift, size - byteShift),
        memset(p + size - byteShift, 0, byteShift);

    if (bitShift) {
        for (usize i = 0; i < size - 1; ++i)
            p[i] = (p[i] << bitShift) | (p[i+1] >> (8 - bitShift));
        p[size-1] <<= bitShift;
    }
}

void memShr(void* src, usize shift, const usize size) {
    if (!size) return;
    shift %= (size * 8);
    if (!shift) return;

    u8* p = (u8*)src;

    const usize byteShift = shift >> 3;
    const usize bitShift  = shift & 7;

    if (byteShift)
        memmove(p + byteShift, p, size - byteShift),
        memset(p, 0, byteShift);

    if (bitShift) {
        for (usize i = size - 1; i > 0; --i)
            p[i] = (p[i] >> bitShift) | (p[i-1] << (8 - bitShift));
        p[0] >>= bitShift;
    }
}

void memRol(void* src, usize rotate, const usize size) {
    if (!size) return;
    rotate %= (size * 8);
    if (!rotate) return;

    u8 tmp[256];
    if (size <= 256) {
        memcpy(tmp, src, size);
    } else {
        u8* tmpDyn = (u8*)alloca(size);
        memcpy(tmpDyn, src, size);
        memcpy(tmp, tmpDyn, size);
    }

    memShl(src, rotate, size);
    memShr(tmp, (size * 8) - rotate, size);

    for (usize i = 0; i < size; ++i)
        ((u8*)src)[i] |= tmp[i];
}

void memRor(void* src, usize rotate, const usize size) {
    if (!size) return;
    rotate %= (size * 8);
    if (!rotate) return;

    u8 tmp[256];
    if (size <= 256) {
        memcpy(tmp, src, size);
    } else {
        u8* tmpDyn = (u8*)alloca(size);
        memcpy(tmpDyn, src, size);
        memcpy(tmp, tmpDyn, size);
    }

    memShr(src, rotate, size);
    memShl(tmp, (size * 8) - rotate, size);

    for (usize i = 0; i < size; ++i)
        ((u8*)src)[i] |= tmp[i];
}
