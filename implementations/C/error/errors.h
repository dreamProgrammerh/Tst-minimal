#pragma once

#include "../utils/short-types.h"
#include "../utils/strings.h"

enum SourceErrorKind {
    SE_LexerError
};

static const
char* SourceErrorKind_names[] = {
    "LexerError"
};

typedef struct SourceError {
    str_t message;
    str_t details;
    u32 offset;
    u32 length;
    enum SourceErrorKind kind;
} SourceError;

static inline
SourceError serr_new(
    const enum SourceErrorKind kind,
    const str_t message, const str_t details,
    const u32 offset, const u32 length
) {
    return (SourceError) {
        .kind = kind,
        .message = message,
        .details = details,
        .offset = offset,
        .length = length
    };
}

static inline
str_t serr_toString(const SourceError* se) {
    return str_b("%s(%s) at offset %u",
        SourceErrorKind_names[se->kind], se->message.data, se->offset);
}

str_t serr_format(const SourceError* se, string_t src, str_t filename, bool colored);

