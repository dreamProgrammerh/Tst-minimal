#pragma once

#include "short-types.h"

typedef struct str_t {
    byte* data;
    u32 length;
} str_t;

typedef struct string_t {
    const byte* data;
    u32 length;
} string_t;