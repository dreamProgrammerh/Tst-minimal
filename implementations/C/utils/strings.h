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