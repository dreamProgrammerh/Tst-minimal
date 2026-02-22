#pragma once

#include "short-types.h"

typedef struct mem_t {
    void* address;
    usize size;
} mem_t;

/* Copy from src to dst by size in bytes */
void memCopy(void* src, void* dst, usize size);

/* Swap memA with memB by size in bytes */
void memSwap(void* memA, void* memB, usize size);

/* Move src to dst by size in bytes and reset src to 0 */
void memMove(void* src, void* dst, usize size);

/* Compare byte by byte for size bytes, src with dst */
i32 memCmp(void* src, void* dst, usize size);

/* Set each byte in src to value for size bytes */
void memSet(void* src, u8 value, usize size);

/* Shift size bytes by shift bits to left in src */
void memShl(void* src, usize shift, usize size);

/* Shift size bytes by shift bits to right in src */
void memShr(void* src, usize shift, usize size);

/* Rotate size bytes by rotate bits to left in src */
void memRol(void* src, usize rotate, usize size);

/* Rotate size bytes by rotate bits to right in src */
void memRor(void* src, usize rotate, usize size);
