#pragma once

#include "../utils/short-types.h"
#include "../lexer/token.h"
#include "../program/program.h"
#include "ast.h"

typedef struct Parser {
    Program* program;
    TokenList tokens;
    u32 position;
} Parser;

bool Parser_isValid(const Parser* ps);

AstArena Parser_parse(Parser* ps);

Parser* Parser_reset(Parser* ps);

bool Parser_isFinished(const Parser* ps);
