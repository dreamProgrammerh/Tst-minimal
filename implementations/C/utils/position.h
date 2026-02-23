#pragma once

#include "short-types.h"

static inline
void pos_getOffsetInfo(
    const char* src, const usize srcLen, const u32 offset,
    u32* row, u32* col, u32* lineStart, u32* lineLength
) {
    *row = 1;
    *col = 1;
    *lineStart = 0;
    *lineLength = 0;

    for (u32 i = 0; i < srcLen && i < offset; i++) {
        if (src[i] != '\n') {
            (*col)++;
            continue;
        }

        *lineStart = i + 1;
        (*row)++;
        *col = 1;
    }

    for (u32 end = *lineStart;
        end < srcLen && src[end] != '\n'; end++) {
        (*lineLength)++;
    }
}
