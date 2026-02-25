#include <stdio.h>

#include "error/errors.h"
#include "error/reporter.h"
#include "lexer/lexer.h"
#include "utils/globals.h"

int main(const int argc, char* argv[]) {
    initGlobals(argc, argv);

    Source src = source_of(
        "hello, world #ffe23a2\n"
        " 123 0xffed 0b1101011 0o327316 0miior3 0moi63 12.34 1e5 6e-5 1e+10\n"
        " === == ~== !~= ** * / /% % ^^ ^ & && | || - + \n",
        "idk.tstm"
    );

    // TODO: replace all hardcoded values with guess based on source.
    StringPool pool = strPool_new(1024, 1024);
    ErrorReporter reporter = reporter_new(100, reporter_defaultPrinter,
        REPORT_COLORED | REPORT_BREAK_ON_PUSH);

    Program program = {
        .stringPool = &pool,
        .source = &src,
        .reporter = &reporter,
    };

    Lexer lexer = {
        .program = &program,
        .position = 0,
    };

    const TokenList tl = Lexer_lex(&lexer);

    for (int i = 0; i < tl.length; i++) {
        const string_t str = tok_toStringColord(tl.tokens[i]);
        printf("%.*s\n", (int) str.length, str.data);
    }

    reporter_throwIfAny(&reporter, src);

    toklist_release(&tl);
    strPool_release(&pool);

    cleanupGlobals();
    return 0;
}