#include "strings.h"
#include "memory.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

str_t str_build(const u32 length, const char* data, ...) {
    char* buf = malloc(length + 1024);

    va_list args;
    va_start(args, data);

    const i32 len = vsnprintf(buf, sizeof(buf), data, args);

    va_end(args);

    const char* str = memClone(buf, len);
    free(buf);

    return (str_t){ .data = str, .length = (u32)len };
}

string_t string_build(const u32 length, char* data, ...) {
    char* buf = malloc(length + 1024);

    va_list args;
    va_start(args, data);

    const i32 len = vsnprintf(buf, sizeof(buf), data, args);

    va_end(args);

    char* str = memClone(buf, len);
    free(buf);

    return (string_t){ .data = str, .length = (u32)len };
}