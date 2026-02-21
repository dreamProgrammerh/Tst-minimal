#pragma once

#include "short-types.h"

typedef struct str_t {
    char* data;
    u32 length;
} str_t;

typedef struct string_t {
    const char* data;
    u32 length;
} string_t;

static inline
str_t str_new(char* data, const u32 length) {
    return (str_t){ .data=data, .length=length };
}

static inline
string_t string_new(const char* data, const u32 length) {
    return (string_t){ .data=data, .length=length };
}

#define str_lit(str) str_new((str), sizeof(str) - 1)
#define string_lit(str) string_new((str), sizeof(str) - 1)