#include "errors.h"
#include "../constants/const-errors.h"
#include "../utils/strings.h"
#include "../utils/memory.h"
#include "../utils/position.h"

#include <stdio.h>
#include <stdlib.h>

string_t serr_format(const SourceError* se, const Source src, const bool colored) {
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

    // Mini arena for strings
    const usize memLen = se->message.length +
        fname.length + details.length + underlineLen + lineLen + 5; // +4 null terminator
    void* mem = malloc(memLen);
    usize memi = 0;

    // Build filename c string
    char* fileNameStr = mem + memi;
    memi += fname.length + 1;
    for (u32 i = 0; i < fname.length; i++) fileNameStr[i] = fname.data[i];
    fileNameStr[fname.length] = '\0';

    // Build details c string
    char* detailsStr = mem + memi;
    memi += details.length + 1;
    for (u32 i = 0; i < details.length; i++) detailsStr[i] = details.data[i];
    detailsStr[details.length] = '\0';

    // Build message c string
    char* messageStr = mem + memi;
    memi += se->message.length + 1;
    for (u32 i = 0; i < se->message.length; i++) messageStr[i] = se->message.data[i];
    messageStr[se->message.length] = '\0';

    // Get target line from src
    char* lineStr = mem + memi;
    memi += lineLen + 1;
    const char* p = src.data + lineStart;
    for (u32 i = 0; i < lineLen; i++) lineStr[i] = p[i];
    lineStr[lineLen] = '\0';

    // Build the inductor underline c string
    char* underlineStr = mem + memi;
    memi += underlineLen + 1;
    for (u32 i = 0; i < spaceCount; i++) underlineStr[i] = ' ';
    for (u32 i = spaceCount; i < underlineLen; i++) underlineStr[i] = '^';
    underlineStr[underlineLen] = '\0';

    // Build result format string
    char* result = malloc((memLen + 1024) * sizeof(char));

    u32 len = 0;
    if (colored) {
        len = sprintf(result,
            ErrClr_errorType"%s"
            ErrClr_punctuation"("
            ErrClr_message"%s"
            ErrClr_punctuation")\n"
            "    "
            ErrClr_context"File "
            ErrClr_name"%s "
            ErrClr_context"at "
            ErrClr_symbols"@"
            ErrClr_location"%u"
            ErrClr_symbols":"
            ErrClr_location"%u\n"
            "\n"
            ErrClr_reset"%s\n"
            ErrClr_caret"%s\n"
            "%s"ErrClr_reset,
            SourceErrorKind_names[se->kind],
            messageStr,
            fileNameStr,
            line, col,
            lineStr,
            underlineStr,
            detailsStr
        );
    } else {
        len = sprintf(result,
            "%s(%s)\n"
            "    File %s at @%u:%u\n"
            "\n"
            "%s\n"
            "%s\n"
            "%s",
            SourceErrorKind_names[se->kind],
            messageStr,
            fileNameStr,
            line, col,
            lineStr,
            underlineStr,
            detailsStr
        );
    }

    char* clone = memClone(result, len);
    free(result);
    free(mem);

    return (string_t) { .data = clone, .length = len };
}
