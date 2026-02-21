#include <stdio.h>

#include "lexer/lexer.h"

int main(int argc, char* argv[]) {
    Lexer lexer = {
        .position = 0,
        .src = string_lit("hello, world #ffe23a2"
            " 123 0xffed 0b1101011 0o327316 12.34 1e5 6e-5 1e+10"
            " === == ~== !~= ** * / /% % ^^ ^ & && | || - + "),
    };

    TokenList* tl = Lexer_lex(&lexer);

    for (int i = 0; i < tl->length; i++) {
        printf("%u: %s\n", tl->tokens[i].type, tl->tokens[i].lexeme.data);
    }

    toklist_free(tl);
    return 0;
}
