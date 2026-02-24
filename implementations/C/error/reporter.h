#pragma once

#include "errors.h"

#define REPORT_NULL                (1u << 0)
#define REPORT_COLORED             (1u << 1)
#define REPORT_BREAK_ON_PUSH       (1u << 2)
#define REPORT_PRINT_IMMEDIATELY   (1u << 3)
#define REPORT_ENABLE              (1u << 4)

#define REPORTER_NULL ((ErrorReporter) { .flags = REPORT_NULL });

typedef void (*ErrorPrinter)(string_t);

typedef struct ErrorReporter {
    struct errorsList {
        SourceError* errs;
        usize length;
        usize capacity;
    } errors;
    ErrorPrinter printer;
    u8 flags;
} ErrorReporter;

ErrorReporter reporter_new(usize capacity, ErrorPrinter printer, u8 flags);

static inline
bool reporter_isNull(const ErrorReporter* reporter) {
    return (reporter->flags & REPORT_NULL) != 0;
}

static inline
bool reporter_hasErrors(const ErrorReporter* reporter) {
    return reporter->errors.length != 0;
}

static inline
bool reporter_hasBreakError(const ErrorReporter* reporter) {
    return (reporter->flags & REPORT_BREAK_ON_PUSH) && reporter->errors.length != 0;
}

void reporter_clear(ErrorReporter* reporter);
bool reporter_push(ErrorReporter* re, SourceError error, Source src);
string_t reporter_formatAll(const ErrorReporter* re, Source src);
bool reporter_throwIfAny(const ErrorReporter* re, Source src);
void reporter_log(string_t string);

void reporter_defaultPrinter(string_t string);