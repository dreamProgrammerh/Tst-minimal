#include "reporter.h"
#include "../utils/memory.h"
#include "../program/source.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static inline
bool _reporter_tryGrow(ErrorReporter* re) {
    if ((float)re->errors.length <= (float)re->errors.capacity * 0.90f) return false;

    const usize newCapacity = (usize)((float)re->errors.capacity * 1.75f);

    SourceError* errors = malloc(newCapacity * sizeof(SourceError));
    if (!errors) {
        fprintf(stderr, "Reporter push Error: Memory allocation failed during growing.\n");
        return true;  // Return true on failure
    }

    memCopy(errors, re->errors.errs, re->errors.length * sizeof(SourceError));
    free(re->errors.errs);

    re->errors.errs = errors;
    re->errors.capacity = newCapacity;
    re->errors.length = re->errors.length;
    return false;  // Return false on success
}

ErrorReporter reporter_new(const usize capacity, const ErrorPrinter printer, const u8 flags)  {
    ErrorReporter rep;
    rep.printer = printer;
    rep.flags = flags | REPORT_ENABLE;

    rep.errors.errs = malloc(capacity * sizeof(ErrorReporter));
    if (!rep.errors.errs) return REPORTER_NULL;

    rep.errors.length = 0;
    rep.errors.capacity = capacity;

    return rep;
}

void reporter_clear(ErrorReporter* reporter) {
    if (!reporter) return;

    free(reporter->errors.errs);
    reporter->errors.errs = NULL;
    reporter->errors.length = 0;
    reporter->errors.capacity = 0;
}

bool reporter_push(ErrorReporter* re, const SourceError error, const Source src) {
    if (!re) return false;
    if (!(re->flags & REPORT_ENABLE)) return false;
    if (re->errors.errs == NULL) return false;
    if (_reporter_tryGrow(re)) return false;

    re->errors.errs[re->errors.length++] = error;
    if (re->flags & REPORT_PRINT_IMMEDIATELY) {
        const string_t str = serr_format(&error, src, (re->flags & REPORT_COLORED) != 0);
        re->printer(str);
    }

    return (re->flags & REPORT_BREAK_ON_PUSH) != 0;
}
string_t reporter_formatAll(const ErrorReporter* re, const Source src) {
    if (!re) return string_null;

    usize resLength = 0;
    string_t* errors = malloc(re->errors.length * sizeof(str_t));

    if (!errors) return string_null;

    // Format all errors
    if (src.data == str_null.data) {
        for (u32 i = 0; i < re->errors.length; i++) {
            errors[i] = serr_toString(&re->errors.errs[i]);
            resLength += errors[i].length;
        }
    } else {
        for (u32 i = 0; i < re->errors.length; i++) {
            errors[i] = serr_format(&re->errors.errs[i], src, re->flags & REPORT_COLORED);
            resLength += errors[i].length;
        }
    }

    // Add space for separators between errors
    if (re->errors.length > 0) {
        resLength += (re->errors.length - 1) * 2; // "\n\n" is 2 characters
    }

    // Join errors into res the separator is "\n\n"
    char* res = malloc(resLength + 1); // +1 for null terminator
    if (!res) {
        // Clean up errors before returning
        for (u32 i = 0; i < re->errors.length; i++) free(errors[i].data);
        free(errors);
        return string_null;
    }

    char* current = res;
    for (u32 i = 0; i < re->errors.length; i++) {
        const string_t err = errors[i];

        // Add separator if not the first error
        if (i != 0) {
            *current++ = '\n';
            *current++ = '\n';
        }

        // Copy error string
        for (u32 j = 0; j < err.length; j++)
            *current++ = err.data[j];

        // Free the individual error string
        free((void*)err.data);
    }

    // Null terminate the result
    *current = '\0';

    // Free the errors array
    free(errors);

    return (string_t) { .data=res, .length=resLength };
}

bool reporter_throwIfAny(const ErrorReporter* re, const Source src) {
    if (!re) return false;
    if (!reporter_hasErrors(re)) return false;

    const string_t msg = reporter_formatAll(re, src);
    re->printer(msg);
    free(msg.data);

    return true;
}

void reporter_log(const string_t string) {
    if (!string.data) return;
    fprintf(stderr, "%.*s", (int)string.length, string.data);
}

void reporter_defaultPrinter(const string_t string) {
    for (u32 i = 0; i < string.length; i++)
        putc(string.data[i], stdout);

    putc('\n', stdout);
    fflush(stdout);
}