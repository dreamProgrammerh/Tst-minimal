#pragma once

#include "../utils/short-types.h"
#include "../utils/strings.h"
#include "token.h"

typedef struct Lexer {
    string_t src;
    u32 position;
    char ch;
} Lexer;

TokenList* Lexer_lex(Lexer* lx);