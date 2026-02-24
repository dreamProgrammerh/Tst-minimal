#include "lexer.h"
#include "lex-func.c"
#include "token.h"

#include <stdlib.h>

bool Lexer_isValid(const Lexer* lx) {
    if (!lx) {
        reporter_log(string_lit("Lexer is NULL!"));
        return false;
    }
    if (!lx->program) {
        reporter_log(string_lit("Lexer have no program!"));
        return false;
    }
    if (!lx->program->source) {
        reporter_log(string_lit("Lexer have no source!"));
        return false;
    }
    if (!lx->program->stringPool) {
        reporter_log(string_lit("Lexer have no string pool!"));
        return false;
    }
    if (!lx->program->reporter) {
        reporter_log(string_lit("Lexer have no reporter!"));
        return false;
    }

    return true;
}

TokenList Lexer_lex(Lexer* lx) {
    const usize gassed_capacity = _lex_countTokensApprox(lx->program->source->data, lx->program->source->dataLength);
    TokenList tokens = toklist_new(gassed_capacity, malloc, free);
    
    while (!_lex_isAtEnd(lx)) {
      const Token token = _lex_nextTok(lx);
      if (token.type == INVALID_TOKEN.type) break;
      
      toklist_push(&tokens, token);
    }

    toklist_push(&tokens, tok_new(tt_eof, str_null, lx->position));
    lx->position = lx->program->source->dataLength;

    return tokens;
}

Lexer* Lexer_reset(Lexer* lx) {
    lx->position = 0;
    return lx;
}

bool Lexer_isFinished(const Lexer* lx) {
    return lx->position == lx->program->source->dataLength;
}