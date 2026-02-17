#pragma once

#include "token.h"
#include "lexer.h"

bool _lex_isAtEnd(const Lexer* lx) {
    return lx->position >= lx->src.length;
}

char _lex_current(const Lexer* lx) {
    return _lex_isAtEnd(lx) ? '\0' : lx->src.data[lx->position];;
}

Token _lex_nextTok(Lexer* lx) {
    lx->position++;
    return INVALID_TOKEN;
}