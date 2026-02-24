#pragma once

#include "../utils/short-types.h"

#define source_of(Data, Name) ((Source) { \
    .data = Data, \
    .name = Name, \
    .dataLength = sizeof(Data) - 1, \
    .nameLength = sizeof(Name) - 1 \
})

typedef struct Source {
    char* data;
    char* name;
    u32 dataLength;
    u32 nameLength;
} Source;
