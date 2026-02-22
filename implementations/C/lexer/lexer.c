#include "lexer.h"
#include "lex-func.c"
#include "token.h"

#include <stdlib.h>

TokenList* Lexer_lex(Lexer* lx) {
    const usize gassed_capacity = _lex_countTokensApprox(lx->src.data, lx->src.length);
    TokenList* tokens = toklist_new(gassed_capacity, malloc, free);
    
    while (!_lex_isAtEnd(lx)) {
      const Token token = _lex_nextTok(lx);
      if (token.type == INVALID_TOKEN.type) break;
      
      toklist_push(tokens, token);
    }

    toklist_push(tokens, tok_new(tt_eof, (str_t) { 0 }, lx->position));
    lx->position = lx->src.length;

    return tokens;
}

Lexer* Lexer_reset(Lexer* lx) {
    lx->position = 0;
    return lx;
}

bool Lexer_isFinished(const Lexer* lx) {
    return lx->position == lx->src.length;
}