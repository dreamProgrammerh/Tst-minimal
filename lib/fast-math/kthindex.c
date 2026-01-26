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
 * 2. Supports flexible indexing:
 *    - 0: median element (largest middle for even length)
 *    - Positive k: k-th element from start (1-indexed)
 *    - Negative k: k-th element from end (Python-style)
 * 3. O(n) average time complexity, O(n²) worst-case
 * 4. Memory efficient: uses stack allocation for arrays ≤ 1M elements
 * 5. Thread-safe PRNG (Xorshift64*)
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
 *   k = 3 (3rd smallest from start)
 *   Returns: 5 (index of value 3 in original array)
 *
 * Comparison with Standard Algorithms:
 *   Standard QuickSelect: Returns VALUE of k-th smallest element
 *   This Algorithm: Returns INDEX of k-th smallest element
 *   Full Sort: O(n log n) vs This: O(n) average
 */

#include <stdlib.h>
#include "types.h"

/** Memory allocation threshold for stack vs heap */
#define STACK_MAX_SIZE 1e6          // 1M

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
 * @brief Transform k to valid zero-based index with special handling
 *
 * Transforms input k according to these rules:
 * 1. k = 0 → n/2 (median, largest middle for even)
 * 2. k > 0 → k-1 (convert from 1-based to 0-based indexing)
 * 3. k < 0 → n + k (Python-style negative indexing from end)
 *
 * Examples for n=6:
 *   k=0  → 3 (median)
 *   k=1  → 0 (first element)
 *   k=6  → 5 (last element)
 *   k=-1 → 5 (last element)
 *   k=-2 → 4 (second last element)
 *   k=-6 → 0 (first element)
 *
 * @param i Input position
 * @param len Array length
 * @return Transformed zero-based index in range [0, n-1]
 * @note Does NOT validate bounds for positive k
 */
static inline
i32 _wrap_kth_index(const i32 i, const u32 len) {
    if (i > 0)
        return i - 1;

    if (i < 0)
        return (i32)len + i;

    // i == 0
    return (i32)len / 2;
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
 * @param k Desired position with flexible indexing:
 *   - 0: median element (largest middle if even length)
 *   - Positive: k-th element from start (1-based)
 *   - Negative: k-th element from end (Python-style)
 *   Example for n=6:
 *     k=0 → median (4th smallest)
 *     k=1 → smallest
 *     k=6 → largest
 *     k=-1 → largest
 *     k=-2 → second largest
 * @return Original array index containing the k-th smallest value,
 *   or -1 if:
 *   - n == 0
 *   - k out of range after wrapping
 *   - Memory allocation failure
 *
 * @note For k=1 (smallest) or k=n (largest), uses optimized O(n) search
 * @note Memory: Uses stack allocation for n ≤ 1M, heap otherwise
 * @note Complexity: O(n) average, O(n²) worst-case
 *
 * Example:
 *   arr = [5, 2, 8, 1, 9, 3], n = 6
 *   k=3 → Returns 5 (index of 3, the 3rd smallest from start)
 *   k=-1 → Returns 4 (index of 9, the largest)
 *   k=0 → Returns 0 (index of 5, the median)
 */
i32 KthIndexInt(const i32* arr, const u32 n, const i32 k) {
    if (n == 0) return -1;

    // Transform k (median/negative handling)
    const i32 K = _wrap_kth_index(k, n);
    if (K < 0 || K >= (i32)n) return -1;

    // Faster edge cases
    if (n == 1) return 0;

    if (K == 0) {
        // Find minimum element by comparing all with first
        i32 minIdx = 0;
        for (u32 i = 1; i < n; i++) {
            if (arr[i] < arr[minIdx]) minIdx = i;
        }
        return minIdx;
    }

    if (K == (i32)n - 1) {
        // Find maximum element by comparing all with first
        i32 maxIdx = 0;
        for (u32 i = 1; i < n; i++) {
            if (arr[i] > arr[maxIdx]) maxIdx = i;
        }
        return maxIdx;
    }

    // Memory allocation strategy
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
 * @param k Desired position with same flexible indexing as KthIndexInt
 * @return Original array index, or -1 on error
 *
 * @note Handles NaN values: NaN compares as greater than any number
 * @note Uses median-of-three pivot selection for better performance
 *
 * Example:
 *   arr = [5.5, 2.2, 8.8, 1.1, 9.9, 3.3], n=6
 *   k=0 → Returns 0 (index of 5.5, the median)
 *   k=2 → Returns 1 (index of 2.2, the 2nd smallest)
 */
i32 KthIndexDouble(const f64* arr, const u32 n, const i32 k) {
    if (n == 0) return -1;

    // Transform k (median/negative handling)
    const i32 K = _wrap_kth_index(k, n);
    if (K < 0 || K >= (i32)n) return -1;

    // Faster edge cases
    if (n == 1) return 0;

    if (K == 0) {
        // Find minimum element by comparing all with first
        i32 minIdx = 0;
        for (u32 i = 1; i < n; i++) {
            if (arr[i] < arr[minIdx]) minIdx = i;
        }
        return minIdx;
    }

    if (K == (i32)n - 1) {
        // Find maximum element by comparing all with first
        i32 maxIdx = 0;
        for (u32 i = 1; i < n; i++) {
            if (arr[i] > arr[maxIdx]) maxIdx = i;
        }
        return maxIdx;
    }

    // Memory allocation strategy
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

/** Context comparison function type */
typedef i32 (*CompareWithContext)(void*, const i32, const i32);

/**
 * @brief Find original index of k-th element in generic array
 *
 * Generic version that works with any data type using a custom comparison
 * function. This is useful for complex structures (e.g., colors, points).
 *
 * @param arr Pointer to array of any type (read-only)
 * @param n Number of elements
 * @param k Desired position with same flexible indexing as KthIndexInt
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
 *   KthIndexGeneric(colors, 5, 0, sizeof(Color), compare_brightness);
 * @endcode
 */
i32 KthIndexGeneric(const void* arr, const u32 n, const i32 k, const size_t elementSize, const compareFunc compare) {
    if (n == 0) return -1;

    // Transform k (median/negative handling)
    const i32 K = _wrap_kth_index(k, n);
    if (K < 0 || K >= (i32)n) return -1;

    // Faster edge cases
    if (n == 1) return 0;

    if (K == 0) {
        // Find minimum element by comparing all with first
        i32 minIdx = 0;
        for (u32 i = 1; i < n; i++) {
            const void* p1 = arr + i * elementSize;
            const void* p2 = arr + minIdx * elementSize;
            if (compare(p1, p2) < 0) minIdx = i;
        }
        return minIdx;
    }

    if (K == (i32)n - 1) {
        // Find maximum element by comparing all with first
        i32 maxIdx = 0;
        for (u32 i = 1; i < n; i++) {
            const void* p1 = arr + i * elementSize;
            const void* p2 = arr + maxIdx * elementSize;
            if (compare(p1, p2) > 0) maxIdx = i;
        }
        return maxIdx;
    }

    // Memory allocation strategy
    const bool large = n > STACK_MAX_SIZE;

    // Create array of indices [0, 1, 2, ..., n-1]
    i32* indices;
    if (large)
        indices = malloc(n * sizeof(i32));

    else
        indices = alloca(n * sizeof(i32));

    if (!indices) return -1;

    for (i32 i = 0; i < n; i++) indices[i] = i;

    const char* base = arr;  // Base pointer for element access
    i32 left = 0;
    i32 right = n - 1;

    while (left < right) {
        // Choose random pivot index
        const i32 pivotIndex = left + (_xorshift64star() % (right - left + 1));

        // Get pivot element from original array
        const void* pivotPtr = base + indices[pivotIndex] * elementSize;

        // Move pivot index to the end
        i32 temp = indices[pivotIndex];
        indices[pivotIndex] = indices[right];
        indices[right] = temp;

        i32 storeIndex = left;
        for (i32 i = left; i < right; i++) {
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
* @brief Find k-th smallest element using only a comparison function
*
* This is a pure comparison-based selection algorithm that doesn't require
* access to the actual data array. All comparisons are performed through
* the provided comparison function.
*
* @param n Number of elements to consider (indices 0 to n-1)
* @param k Desired position with same flexible indexing as KthIndexInt
* @param context User context passed to comparison function
* @param compare Comparison function that compares two indices
* @return Index of the k-th smallest element, or -1 on error
*
* @note The comparison function should compare elements at indices a and b
* @note Complexity: O(n) average, O(n²) worst-case
* @note Memory: O(n) for indices only
*
* Example for colors by brightness:
*   typedef struct { uint8_t r, g, b; } Color;
*   Color* colors = ...;
*
*   int32_t compare_brightness(void* ctx, int32_t a, int32_t b) {
*       Color* colors = (Color*)ctx;
*       double ba = 0.299*colors[a].r + 0.587*colors[a].g + 0.114*colors[a].b;
*       double bb = 0.299*colors[b].r + 0.587*colors[b].g + 0.114*colors[b].b;
*       return (ba > bb) - (ba < bb);
*   }
*
*   // Find median brightness color
*   int32_t median_idx = KthIndexContext(
*       5, 0, colors, compare_brightness
*   );
*/
i32 KthIndexContext(const u32 n, const i32 k, void* context, const CompareWithContext compare) {
    if (n == 0) return -1;

    // Transform k (median/negative handling)
    const i32 K = _wrap_kth_index(k, n);
    if (K < 0 || K >= (i32)n) return -1;

    // Faster edge cases
    if (n == 1) return 0;

    if (K == 0) {
        // Find minimum element by comparing all with first
        i32 minIdx = 0;
        for (u32 i = 1; i < n; i++) {
            if (compare(context, i, minIdx) < 0) minIdx = i;
        }
        return minIdx;
    }

    if (K == (i32)n - 1) {
        // Find maximum element by comparing all with first
        i32 maxIdx = 0;
        for (u32 i = 1; i < n; i++) {
            if (compare(context, i, maxIdx) > 0) maxIdx = i;
        }
        return maxIdx;
    }
    
    // Memory allocation strategy
    const bool large = n > STACK_MAX_SIZE;
    i32* indices;
    
    if (large)
        indices = malloc(n * sizeof(i32));
    
    else 
        indices = alloca(n * sizeof(i32));
    
    if (!indices) return -1;
    
    // Initialize indices [0, 1, 2, ..., n-1]
    for (u32 i = 0; i < n; i++) indices[i] = i;
    
    // QuickSelect on indices using only comparison function
    i32 left = 0;
    i32 right = n - 1;
    
    while (left < right) {
        // Choose random pivot index
        const i32 pivotIndex = left + (_xorshift64star() % (right - left + 1));
        
        // Get pivot index
        const i32 pivotNewIndex = indices[pivotIndex];
        
        // Move pivot to end
        i32 temp = indices[pivotIndex];
        indices[pivotIndex] = indices[right];
        indices[right] = temp;
        
        i32 storeIndex = left;
        for (i32 i = left; i < right; i++) {
            // Compare element at indices[i] with pivot element
            if (compare(context, indices[i], pivotNewIndex) < 0) {
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