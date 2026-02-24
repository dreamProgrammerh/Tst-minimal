#include "errors.h"
#include "../constants/const-errors.h"
#include "../utils/memory.h"
#include "../utils/position.h"
#include "../utils/strings.h"

#include <stdio.h>

string_t serr_format(const SourceError* se, const Source src, const bool colored) {
    char buffer[2048];

    const str_t fname = src.name == NULL
        ? str_lit("<anonymous>") : str_new(src.name, src.nameLength);

    const str_t details = se->details.data == str_null.data
        ? str_lit("( No Details Provided )") : se->details;

    // Get required position info
    u32 line, col, lineStart, lineLen;
    pos_getOffsetInfo(src.data, src.dataLength, se->offset,
        &line, &col, &lineStart, &lineLen);

    const u32 spaceCount = col - 1;
    const u32 caretCount = se->length;
    const u32 underlineLen = spaceCount + caretCount;

    char underline[underlineLen];

    for (u32 i = 0; i < spaceCount; i++) underline[i] = ' ';
    for (u32 i = spaceCount; i < underlineLen; i++) underline[i] = '^';

    // Get target line from src
    const char* srcLine = src.data + lineStart;

    // Build result format string
    u32 len = 0;
    if (colored) {
        len = snprintf(buffer, sizeof(buffer),
            ErrClr_errorType"%s"
            ErrClr_punctuation"("
            ErrClr_message"%.*s"
            ErrClr_punctuation")\n"
            "    "
            ErrClr_context"File "
            ErrClr_name"%.*s "
            ErrClr_context"at "
            ErrClr_symbols"@"
            ErrClr_location"%u"
            ErrClr_symbols":"
            ErrClr_location"%u\n"
            "\n"
            ErrClr_reset"%.*s\n"
            ErrClr_caret"%.*s\n"
            "%.*s"ErrClr_reset,
            SourceErrorKind_names[se->kind],
            se->message.length, se->message.data,
            fname.length, fname.data,
            line, col,
            lineLen, srcLine,
            underlineLen, underline,
            details.length, details.data
        );
    } else {
        len = snprintf(buffer, sizeof(buffer),
            "%s(%.*s)\n"
            "    File %.*s at @%u:%u\n"
            "\n"
            "%.*s\n"
            "%.*s\n"
            "%.*s",
            SourceErrorKind_names[se->kind],
            se->message.length, se->message.data,
            fname.length, fname.data,
            line, col,
            lineLen, srcLine,
            underlineLen, underline,
            details.length, details.data
        );
    }

    if (len >= sizeof(buffer)) {
        // Truncation occurred - put three dot at end
        buffer[sizeof(buffer)-1] = '.';
        buffer[sizeof(buffer)-2] = '.';
        buffer[sizeof(buffer)-3] = '.';

        // TODO: add log file property at program if it not null,
        //  log into that file.
    }

    char* clone = memClone(buffer, len);
    return (string_t) { .data = clone, .length = len };
}
