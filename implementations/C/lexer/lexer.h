#pragma once

#include "../utils/short-types.h"
#include "../utils/strings.h"
#include "../program/program.h"
#include "token.h"

typedef struct Lexer {
    Program* program;
    u32 position;
} Lexer;

#define LEXER_AT(lx, i) (lx->program->source->data[i])
#define LEXER_LEN(lx) (lx->program->source->dataLength)
#define LEXER_CH(lx) LEXER_AT(lx, lx->position)

TokenList Lexer_lex(Lexer* lx);

Lexer* Lexer_reset(Lexer* lx);

bool Lexer_isFinished(const Lexer* lx);