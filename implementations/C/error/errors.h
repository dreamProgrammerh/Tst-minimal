#pragma once

#include "../utils/short-types.h"
#include "../utils/strings.h"
#include "../program/source.h"

enum SourceErrorKind {
    SE_LexerError,
    SE_ParserError,
};

static const
char* SourceErrorKind_names[] = {
    "LexerError",
    "ParserError"
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
string_t serr_toString(const SourceError* se) {
    return string_b("%s(%s) at offset %u",
        SourceErrorKind_names[se->kind], se->message.data, se->offset);
}

string_t serr_format(const SourceError* se, Source src, bool colored);

