#pragma once

#include "short-types.h"

typedef struct str_t {
    const char* data;
    u32 length;
} str_t;

typedef struct string_t {
    char* data;
    u32 length;
} string_t;

typedef struct StringB {
    char* data;
    usize length;
    usize capacity;
} StringB;

#define str_null ((str_t) { 0 })
#define string_null ((string_t) { 0 })

static inline
str_t str_new(const char* data, const u32 length) {
    return (str_t){ .data=data, .length=length };
}

static inline
string_t string_new(char* data, const u32 length) {
    return (string_t){ .data=data, .length=length };
}

#define str_lit(str) str_new((str), sizeof(str) - 1)
#define string_lit(str) string_new((str), sizeof(str) - 1)

str_t str_build(u32 length, const char* data, ...);
string_t string_build(u32 length, char* data, ...);

#define str_b(str, ...) str_build(sizeof(str) - 1, str, __VA_ARGS__)
#define string_b(str, ...) string_build(sizeof(str) - 1, str, __VA_ARGS__)