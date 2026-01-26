/**
 * @file kthindex.c
 * @brief Index-Preserving QuickSelect Algorithm
 *
 * This module implements a novel variant of the QuickSelect algorithm that
 * returns the ORIGINAL INDEX of the k-th smallest element in an array,
 * without modifying the input array. The algorithm preserves the original
 * indices while efficiently finding order statistics.
 *
 * Key Features:
 * 1. Returns original index, not value (unlike standard QuickSelect)
 * 2. Supports negative indexing: -1 = largest, -2 = second largest, etc.
 * 3. Special sentinel value 0xFFFFFFFF for median (largest middle for even length)
 * 4. O(n) average time complexity, O(n²) worst-case
 * 5. Memory efficient: uses stack allocation for arrays ≤ 1M elements
 * 6. Thread-safe PRNG (Xorshift64*)
 *
 * Algorithm: A hybrid of QuickSelect and indirect sorting that operates on
 * indices rather than values, maintaining the mapping to original positions.
 *
 * Typical Use Cases:
 * - Finding which color has median brightness in an image
 * - Identifying which data point is at a specific percentile
 * - Selecting representative elements without sorting the entire dataset
 * - Database queries for order statistics with position information
 *
 * Example:
 *   Array: [5.0, 2.0, 8.0, 1.0, 9.0, 3.0]
 *   k = 2 (0-indexed, 3rd smallest)
 *   Returns: 5 (index of value 3 in original array)
 *
 * Comparison with Standard Algorithms:
 *   Standard QuickSelect: Returns VALUE of k-th smallest element
 *   This Algorithm: Returns INDEX of k-th smallest element
 *   Full Sort: O(n log n) vs This: O(n) average
 */

#include <stdlib.h>
#include "types.h"

/** Sentinel value indicating median should be returned */
#define STACK_MAX_SIZE 1e6          // 1M
#define KTH_MEDIAN 0xFFFFFFFFu      // Use for median case

/** Fast Xorshift64* PRNG seed (thread-safe static) */
static u64 _kth_seed = 88172645463325252ULL;

/**
 * @brief Fast Xorshift64* pseudo-random number generator
 *
 * High-quality, fast PRNG suitable for pivot selection.
 * Thread-safe due to static seed (not reentrant across threads).
 *
 * @return 64-bit random number
 */
static inline
u64 _xorshift64star() {
    _kth_seed ^= _kth_seed >> 12;
    _kth_seed ^= _kth_seed << 25;
    _kth_seed ^= _kth_seed >> 27;
    return _kth_seed * 0x2545F4914F6CDD1DULL;
}

/**
 * @brief Wrap k to valid index range with special handling
 *
 * Transforms input k according to these rules:
 * 1. KTH_MEDIAN (0xFFFFFFFF) → n/2 (median, largest middle for even)
 * 2. Negative k → n + k (Python-style negative indexing)
 * 3. Positive k → unchanged (must be validated separately)
 *
 * @param i Input position (can be negative or KTH_MEDIAN)
 * @param len Array length
 * @return Transformed index in range [0, n-1] for median/negative cases
 * @note Does NOT validate bounds for positive k
 */
static inline
i32 _wrap_kth_index(const i32 i, const u32 len) {
    if (i == KTH_MEDIAN)
        return (i32)len / 2;

    if (i < 0)
        return (i32)len + i;

    return i;
}


/**
 * @brief Find original index of k-th smallest integer in array
 *
 * Uses QuickSelect algorithm operating on indices to efficiently find
 * which position in the original array contains the k-th smallest value.
 * The array is never modified.
 *
 * @param arr Pointer to integer array (read-only)
 * @param n Number of elements in array (must be > 0)
 * @param k Desired position in sorted order:
 *   - 0: smallest element
 *   - n-1: largest element
 *   - -1: largest element (same as n-1)
 *   - -2: second largest element
 *   - KTH_MEDIAN (0xFFFFFFFF): median element (largest middle if even)
 * @return Original array index containing the k-th smallest value,
 *   or -1 if:
 *   - n == 0
 *   - k out of range after wrapping (except KTH_MEDIAN)
 *   - Memory allocation failure
 *
 * @note For k = 0 or k = n-1, uses optimized O(n) search instead of QuickSelect
 * @note Memory: Uses stack allocation for n ≤ 1M, heap otherwise
 * @note Complexity: O(n) average, O(n²) worst-case
 *
 * Example:
 *   arr = [5, 2, 8, 1, 9, 3], n = 6
 *   k = 2 → Returns 5 (index of 3, the 3rd smallest)
 *   k = -1 → Returns 4 (index of 9, the largest)
 *   k = KTH_MEDIAN → Returns 0 (index of 5, the median)
 */
i32 KthIndexInt(const i32* arr, const u32 n, const i32 k) {
    const i32 K = _wrap_kth_index(k, n);
    if (n <= 0 || K < 0 || K >= n) return -1;

    const bool large = n > STACK_MAX_SIZE;

    i32* indices;
    if (large)
        indices = malloc(n * sizeof(i32));

    else
        indices = alloca(n * sizeof(i32));

    if (!indices) return -1;

    for (i32 i = 0; i < n; i++) indices[i] = i;
    
    i32 left = 0;
    i32 right = n - 1;
    
    while (left < right) {
        const i32 pivotIndex = left + (_xorshift64star() % (right - left + 1));
        
        const i32 pivotValue = arr[indices[pivotIndex]];
        
        i32 temp = indices[pivotIndex];
        indices[pivotIndex] = indices[right];
        indices[right] = temp;
        
        i32 storeIndex = left;
        for (i32 i = left; i < right; i++) {
            if (arr[indices[i]] < pivotValue) {
                temp = indices[i];
                indices[i] = indices[storeIndex];
                indices[storeIndex] = temp;
                storeIndex++;
            }
        }
        
        temp = indices[storeIndex];
        indices[storeIndex] = indices[right];
        indices[right] = temp;
        
        if (K == storeIndex) {
            const i32 result = indices[K];
            if (large) free(indices);
            return result;
        }

        if (K < storeIndex) {
            right = storeIndex - 1;

        } else {
            left = storeIndex + 1;
            
        }
    }
    
    const i32 result = indices[left];
    if (large) free(indices);
    return result;
}


/**
 * @brief Find original index of k-th smallest double in array
 *
 * Similar to KthIndexInt but for double-precision floating-point values.
 * Uses median-of-three pivot selection for better performance on doubles.
 *
 * @param arr Pointer to double array (read-only)
 * @param n Number of elements in array (must be > 0)
 * @param k Desired position (see KthIndexInt for details)
 * @return Original array index, or -1 on error
 *
 * @note Handles NaN values: NaN compares as greater than any number
 * @note Uses median-of-three pivot selection for better performance
 *
 * Example:
 *   arr = [5.5, 2.2, 8.8, 1.1, 9.9, 3.3]
 *   k = KTH_MEDIAN → Returns 0 (index of 5.5, the median)
 */
i32 KthIndexDouble(const f64* arr, const u32 n, const i32 k) {
    const i32 K = _wrap_kth_index(k, n);
    if (n <= 0 || K < 0 || K >= n) return -1;
        
    const bool large = n > STACK_MAX_SIZE;

    i32* indices;
    if (large)
        indices = malloc(n * sizeof(i32));

    else
        indices = alloca(n * sizeof(i32));

    if (!indices) return -1;
    
    for (int i = 0; i < n; i++) indices[i] = i;
    
    int left = 0;
    int right = n - 1;
    
    while (left < right) {
        // Median of three for better pivot
        const int mid = left + (right - left) / 2;
        
        const double a = arr[indices[left]];
        const double b = arr[indices[mid]];
        const double c = arr[indices[right]];
        
        int pivotIndex;
        if ((a < b) != (a < c))
            pivotIndex = left;
            
        else if ((b < a) != (b < c))
            pivotIndex = mid;
            
        else
            pivotIndex = right;
        
        const double pivotValue = arr[indices[pivotIndex]];
        
        // Move pivot to end
        int temp = indices[pivotIndex];
        indices[pivotIndex] = indices[right];
        indices[right] = temp;
        
        int storeIndex = left;
        for (int i = left; i < right; i++) {
            if (arr[indices[i]] < pivotValue) {
                temp = indices[i];
                indices[i] = indices[storeIndex];
                indices[storeIndex] = temp;
                storeIndex++;
            }
        }
        
        temp = indices[storeIndex];
        indices[storeIndex] = indices[right];
        indices[right] = temp;
        
        if (K == storeIndex) {
            const int result = indices[K];
            if (large) free(indices);
            return result;

        }

        if (K < storeIndex) {
            right = storeIndex - 1;

        } else {
            left = storeIndex + 1;

        }
    }
    
    const int result = indices[left];
    if (large) free(indices);
    return result;
}


/** Comparison function type for generic arrays */
typedef i32 (*compareFunc)(const void*, const void*);

/**
 * @brief Find original index of k-th element in generic array
 *
 * Generic version that works with any data type using a custom comparison
 * function. This is useful for complex structures (e.g., colors, points).
 *
 * @param arr Pointer to array of any type (read-only)
 * @param n Number of elements
 * @param k Desired position (see KthIndexInt for details)
 * @param elementSize Size in bytes of each array element
 * @param compare Comparison function returning:
 *   - <0 if first element < second
 *   - 0 if equal
 *   - >0 if first element > second
 * @return Original array index, or -1 on error
 *
 * @note The comparison function should be consistent (transitive, antisymmetric)
 * @note Memory overhead: O(n) for indices only, not data
 *
 * Example for colors by brightness:
 * @code
 *   typedef struct { uint8_t r, g, b; } Color;
 *   int32_t compare_brightness(const void* a, const void* b) {
 *       Color* ca = (Color*)a; Color* cb = (Color*)b;
 *       double ba = 0.299*ca->r + 0.587*ca->g + 0.114*ca->b;
 *       double bb = 0.299*cb->r + 0.587*cb->g + 0.114*cb->b;
 *       return (ba > bb) - (ba < bb);
 *   }
 *   KthIndexGeneric(colors, n, KTH_MEDIAN, sizeof(Color), compare_brightness);
 * @endcode
 */
i32 KthIndexGeneric(const void* arr, const u32 n, const i32 k, const size_t elementSize, const compareFunc compare) {
    const i32 K = _wrap_kth_index(k, n);
    if (n <= 0 || K < 0 || K >= n) return -1;

    const bool large = n > STACK_MAX_SIZE;

    // Create array of indices [0, 1, 2, ..., n-1]
    i32* indices;
    if (large)
        indices = malloc(n * sizeof(i32));

    else
        indices = alloca(n * sizeof(i32));

    if (!indices) return -1;

    for (int i = 0; i < n; i++) indices[i] = i;

    const char* base = arr;  // Base pointer for element access
    int left = 0;
    int right = n - 1;

    while (left < right) {
        // Choose random pivot index
        const int pivotIndex = left + (_xorshift64star() % (right - left + 1));

        // Get pivot element from original array
        const void* pivotPtr = base + indices[pivotIndex] * elementSize;

        // Move pivot index to the end
        int temp = indices[pivotIndex];
        indices[pivotIndex] = indices[right];
        indices[right] = temp;

        int storeIndex = left;
        for (int i = left; i < right; i++) {
            // Compare element at indices[i] with pivot
            const void* currPtr = base + indices[i] * elementSize;
            if (compare(currPtr, pivotPtr) < 0) {
                // Swap indices
                temp = indices[i];
                indices[i] = indices[storeIndex];
                indices[storeIndex] = temp;
                storeIndex++;
            }
        }

        // Move pivot to final position
        temp = indices[storeIndex];
        indices[storeIndex] = indices[right];
        indices[right] = temp;

        if (K == storeIndex) {
            const int result = indices[K];
            if (large) free(indices);
            return result;
        }

        if (K < storeIndex) {
            right = storeIndex - 1;

        } else {
            left = storeIndex + 1;

        }
    }

    const int result = indices[left];
    if (large) free(indices);
    return result;
}