#pragma once

#include "../utils/short-types.h"
#include "../utils/strings.h"

typedef struct StringPool StringPool;

// String header stored before each string
typedef struct StringHeader {
    u32 hash;           // Full hash for quick comparison
    u32 len;            // String length
    char data[];        // Points to memory AFTER header (C trick!)
} StringHeader;

// Hash table entry
typedef struct HashEntry {
    u32 hash;           // Full hash (0 means empty)
    u32 offset;         // Offset in pool where string starts (includes header)
} HashEntry;

struct StringPool {
    // String data storage
    char* data;
    u32 used;
    u32 capacity;

    // Hash table for fast lookup
    HashEntry* hashTable;
    u32 hashCapacity;   // Always power of two
    u32 hashLength;     // Number of used entries
    f32 maxLoad;        // Typically 0.75
};

StringPool strPool_new(u32 initialCapacity, u32 initialHashCapacity);

// Pool intern function
str_t strPool_intern(StringPool* pool, const char* src, u32 len);

// Pool string lookup without inserting
str_t strPool_find(const StringPool* pool, const char* src, u32 len);

// Reset pool for next compilation (reuse memory!)
void strPool_reset(StringPool* pool);

// Free everything inside pool
void strPool_release(const StringPool* pool);
