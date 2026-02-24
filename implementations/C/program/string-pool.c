#include "string-pool.h"
#include "../utils/memory.h"

#include <stdlib.h>

// FNV-1a hash (fast and good)
static inline
u32 _fnv1a_hash(const char* data, const u32 len) {
    u32 hash = 2166136261u;
    for (u32 i = 0; i < len; i++) {
        hash ^= data[i];
        hash *= 16777619;
    }
    return hash;
}

// Grow hash table when load factor exceeded
static inline
void _strPool_growHash(StringPool* pool) {
    const u32 oldCapacity = pool->hashCapacity;
    HashEntry* old_table = pool->hashTable;

    // Double the hash table
    pool->hashCapacity *= 2;
    pool->hashTable = calloc(pool->hashCapacity, sizeof(HashEntry));
    pool->hashLength = 0;

    // Rehash all existing entries
    for (u32 i = 0; i < oldCapacity; i++) {
        if (old_table[i].offset != 0) {
            const u32 hash = old_table[i].hash;
            u32 index = hash & (pool->hashCapacity - 1);

            // Linear probing to find empty slot
            while (pool->hashTable[index].offset != 0) {
                index = (index + 1) & (pool->hashCapacity - 1);
            }

            pool->hashTable[index].hash = hash;
            pool->hashTable[index].offset = old_table[i].offset;
            pool->hashLength++;
        }
    }

    free(old_table);
}

// Ensure space in string storage
static inline
void _strPool_ensureSpace(StringPool* pool, const u32 needed) {
    if (pool->used + needed <= pool->capacity) return;

    // Grow string storage
    u32 newCapacity = pool->capacity;
    while (newCapacity < pool->used + needed) {
        newCapacity *= 2;
    }
    pool->data = realloc(pool->data, newCapacity);
    pool->capacity = newCapacity;
}

// Helper to get string data from header offset
static inline
char* _strPool_dataOfOffset(const StringPool* pool, const u32 offset) {
    // offset points to StringHeader
    // StringHeader->data is at offset + sizeof(StringHeader)
    return pool->data + offset + sizeof(StringHeader);
}

// Helper to get string header from offset
static inline
StringHeader* _strPool_headerOfOffset(const StringPool* pool, u32 const offset) {
    return (StringHeader*)(pool->data + offset);
}

// Create new string pool
StringPool* strPool_new(const u32 initialCapacity, const u32 initialHashCapacity) {
    StringPool* pool = malloc(sizeof(StringPool));

    // String storage
    pool->capacity = initialCapacity;
    pool->data = malloc(initialCapacity);
    pool->used = 0;

    // Hash table (must be power of two)
    pool->hashCapacity = initialHashCapacity;
    pool->hashTable = calloc(initialHashCapacity, sizeof(HashEntry));
    pool->hashLength = 0;
    pool->maxLoad = 0.75f;

    return pool;
}

// Main intern function
str_t strPool_intern(StringPool* pool, const char* src, const u32 len) {
    // 1. Calculate hash
    const u32 hash = _fnv1a_hash(src, len);

    // 2. Find in hash table if it exists
    u32 index = hash & (pool->hashCapacity - 1);
    const u32 firstIndex = index;

    while (pool->hashTable[index].offset != 0) {
        const HashEntry* entry = &pool->hashTable[index];

        // Check hash first (fast)
        if (entry->hash == hash) {
            // Verify with actual string comparison
            const StringHeader* h = _strPool_headerOfOffset(pool, entry->offset);
            if (h->len == len) {
                char* str = _strPool_dataOfOffset(pool, entry->offset);
                // Compare strings (slow but only when hash matches)
                if (memCmp(str, src, len) == 0) {
                    // Found it!
                    return (str_t) { .data = str, .length = len };
                }
            }
        }

        // Linear probe
        index = (index + 1) & (pool->hashCapacity - 1);

        // Prevent infinite loop if table is full (shouldn't happen with maxLoad)
        if (index == firstIndex) break;
    }

    // 3. Not found - need to add new string

    // Check if hash table needs to grow
    if ((float)pool->hashLength / pool->hashCapacity >= pool->maxLoad) {
        _strPool_growHash(pool);

        // Recalculate index for new table
        index = hash & (pool->hashCapacity - 1);
        while (pool->hashTable[index].offset != 0) {
            index = (index + 1) & (pool->hashCapacity - 1);
        }
    }

    // 4. Ensure space in string storage
    const u32 needed = sizeof(StringHeader) + len;
    _strPool_ensureSpace(pool, needed);

    // 5. Write string with header
    const u32 offset = pool->used;
    StringHeader* header = _strPool_headerOfOffset(pool, offset);
    header->hash = hash;
    header->len = len;

    // Write string data AFTER the header
    char* stringDest = (char*)(header + 1);  // Advance past header
    memCopy(stringDest, src, len);

    // 6. Update pool state
    pool->used += needed;

    // 7. Add to hash table
    pool->hashTable[index].hash = hash;
    pool->hashTable[index].offset = offset;
    pool->hashLength++;

    // 8. Return str_t pointing to string data (not header)
    return (str_t) { .data = header->data, .length = len };
}

// Direct string lookup without inserting
str_t strPool_find(const StringPool* pool, const char* src, const u32 len) {
    const u32 hash = _fnv1a_hash(src, len);
    u32 index = hash & (pool->hashCapacity - 1);
    const u32 firstIndex = index;

    while (pool->hashTable[index].offset != 0) {
        const HashEntry* entry = &pool->hashTable[index];
        if (entry->hash == hash) {
            const StringHeader* h = _strPool_headerOfOffset(pool, entry->offset);

            if (h->len == len) {
                char* str = _strPool_dataOfOffset(pool, entry->offset);

                if (memCmp(str, src, len) == 0) {
                    return (str_t) { .data = str, .length = len };
                }
            }
        }
        index = (index + 1) & (pool->hashCapacity - 1);
        if (index == firstIndex) break;
    }

    return str_null;
}

// Reset pool for next compilation (reuse memory!)
void strPool_reset(StringPool* pool) {
    pool->used = 0;
    pool->hashLength = 0;

    // Clear hash table entries
    memSet(pool->hashTable, 0, pool->hashCapacity * sizeof(HashEntry));
}

// Free everything
void strPool_destroy(StringPool* pool) {
    free(pool->data);
    free(pool->hashTable);
    free(pool);
}