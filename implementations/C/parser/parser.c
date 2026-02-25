#include "parser.h"
#include "parse-func.c"

bool Parser_isValid(const Parser* ps) {
    if (!ps) {
        reporter_log(string_lit("Parser is NULL!"));
        return false;
    }
    if (!ps->program) {
        reporter_log(string_lit("Parser have no program!"));
        return false;
    }
    if (!ps->program->source) {
        reporter_log(string_lit("Parser have no source!"));
        return false;
    }
    if (!ps->program->stringPool) {
        reporter_log(string_lit("Parser have no string pool!"));
        return false;
    }
    if (!ps->program->reporter) {
        reporter_log(string_lit("Parser have no reporter!"));
        return false;
    }

    return true;
}

AstArena Parser_parse(Parser* ps) {
    // TODO: guess needed capacitys using tokens length
    AstArena ast = ast_new(100, 100);
    ps->program->ast = &ast; // need to change program struct to accept embedded not pointers

    // TODO: Complete this...

    return ast;
}

Parser* Parser_reset(Parser* ps)  {
    ps->position = 0;
    return ps;
}

bool Parser_isFinished(const Parser* ps) {
    return ps->position == ps->tokens.length;
}