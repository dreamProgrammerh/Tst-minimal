#include "lexer.h"
#include "lex-func.c"
#include "token.h"

#include <stdlib.h>

TokenList* Lexer_lex(Lexer* lx) {
    // TODO: instead of hard coded 100
    //      we must count the space between non-space character
    //      ignoring comments, this way we have more accurate capacity.
    TokenList* tokens = toklist_new(100, malloc, free);
    
    while (!_lex_isAtEnd(lx)) {
      Token token = _lex_nextTok(lx);
      if (token.type == INVALID_TOKEN.type) break;
      
      toklist_push(tokens, token);
    }

    toklist_push(tokens, tok_new(tt_eof, (str_t) { 0 }, lx->position));
    return tokens;
}