#pragma once

#include "../utils/short-types.h"
#include "../utils/strings.h"
#include "token.h"

typedef struct Lexer {
    string_t src;
    u32 position;
} Lexer;

#define LEXER_CH(lx) (lx->src.data[lx->position])

TokenList* Lexer_lex(Lexer* lx);

Lexer* Lexer_reset(Lexer* lx);

bool Lexer_isFinished(const Lexer* lx);