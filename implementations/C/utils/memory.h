#pragma once

#include "short-types.h"

typedef struct mem_t {
    void* address;
    usize size;
} mem_t;

/* ============================================================
   Core Memory Primitives
   ============================================================ */

/**
 * Copies `size` bytes from `src` to `dst`.
 *
 * - Undefined behavior if memory regions overlap.
 * - No allocation is performed.
 * - Optimized for small constant sizes when possible.
 *
 * @param dst   Destination buffer (must be valid for `size` bytes).
 * @param src   Source buffer (must be valid for `size` bytes).
 * @param size  Number of bytes to copy.
 */
void memCopy(void* restrict dst, const void* restrict src, usize size);

/**
 * Copies `size` bytes from `src` to `dst`.
 *
 * - Safe for overlapping regions.
 * - No allocation is performed.
 *
 * @param dst   Destination buffer.
 * @param src   Source buffer.
 * @param size  Number of bytes to move.
 */
void memMove(void* dst, const void* src, usize size);

/**
 * @brief Swap `size` bytes between memory regions `a` and `b`.
 *
 * @param a Pointer to first memory region.
 * @param b Pointer to second memory region.
 * @param size Number of bytes to swap.
 *
 * @note a and b must not be NULL and should be non-overlapping or swapping will be undefined behavior.
 */
void memSwap(void* restrict a, void* restrict b, usize size);

/**
 * Sets `size` bytes at `dst` to `value`.
 *
 * @param dst    Target memory.
 * @param value  Byte value to write.
 * @param size   Number of bytes to set.
 */
void memSet(void* dst, u8 value, usize size);

/**
 * Lexicographically compares two memory regions.
 *
 * Behavior matches standard memcmp:
 *   < 0  if a < b
 *   = 0  if equal
 *   > 0  if a > b
 *
 * Comparison is performed as unsigned bytes.
 *
 * @param a     First memory block.
 * @param b     Second memory block.
 * @param size  Number of bytes to compare.
 *
 * @return Comparison result (-1, 0, 1 or equivalent sign).
 */
i32 memCmp(const void* restrict a, const void* restrict b, usize size);


/* ============================================================
   Allocation Helpers
   ============================================================ */

/**
 * Allocates `size` bytes using malloc and copies `src` into it.
 *
 * @param src   Source buffer.
 * @param size  Number of bytes to duplicate.
 *
 * @return Newly allocated buffer, or NULL on failure.
 */
void* memClone(const void* src, usize size);

/**
 * Allocates `size` bytes using a custom allocator and copies `src` into it.
 *
 * @param src    Source buffer.
 * @param size   Number of bytes to duplicate.
 * @param alloc  Allocation function (must behave like malloc).
 *
 * @return Newly allocated buffer, or NULL on failure.
 */
void* memCloneWith(const void* src, usize size, void* (*alloc)(usize));

/**
 * Moves `size` bytes from `src` to `dst` and zeroes the source region.
 *
 * - Safe for overlapping regions.
 * - Guarantees source memory is cleared afterward.
 *
 * @param dst   Destination buffer.
 * @param src   Source buffer (will be zeroed).
 * @param size  Number of bytes to transfer.
 */
void memTransfer(void* dst, void* src, usize size);


/* ============================================================
   Bit-Level Memory Operations
   ============================================================ */

/**
 * Logical left bit-shift of a byte buffer.
 *
 * Entire buffer is treated as a contiguous big-endian bit stream.
 * Vacated bits are filled with zero.
 *
 * @param data   Target buffer.
 * @param bits   Number of bits to shift.
 * @param size   Buffer size in bytes.
 */
void memBitShl(void* data, usize bits, usize size);

/**
 * Logical right bit-shift of a byte buffer.
 *
 * Entire buffer is treated as a contiguous big-endian bit stream.
 * Vacated bits are filled with zero.
 *
 * @param data   Target buffer.
 * @param bits   Number of bits to shift.
 * @param size   Buffer size in bytes.
 */
void memBitShr(void* data, usize bits, usize size);

/**
 * Bitwise rotate-left of a byte buffer.
 *
 * Entire buffer is treated as a contiguous big-endian bit stream.
 * Bits shifted out of the high end re-enter at the low end.
 *
 * @param data    Target buffer.
 * @param rotate  Number of bits to rotate.
 * @param size    Buffer size in bytes.
 */
void memBitRol(void* data, usize rotate, usize size);

/**
 * Bitwise rotate-right of a byte buffer.
 *
 * Entire buffer is treated as a contiguous big-endian bit stream.
 * Bits shifted out of the low end re-enter at the high end.
 *
 * @param data    Target buffer.
 * @param rotate  Number of bits to rotate.
 * @param size    Buffer size in bytes.
 */
void memBitRor(void* data, usize rotate, usize size);