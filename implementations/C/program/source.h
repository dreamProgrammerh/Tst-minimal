#pragma once

#include "../utils/short-types.h"

typedef struct Source {
    char* data;
    char* name;
    u32 dataLength;
    u32 nameLength;
} Source;
