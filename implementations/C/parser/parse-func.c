#pragma once

#include "parser.h"
#include <strings.h>

bool _prs_isAtEnd(const Parser* ps) {
    return ps->position >= ps->tokens.length;
}

Token _prs_current(const Parser* ps) {
    return _prs_isAtEnd(ps)
        ? INVALID_TOKEN : ps->tokens.tokens[ps->position];
}

Token _prs_peek(const Parser* ps, const u32 offset) {
    return ps->position + offset >= ps->tokens.length
        ? INVALID_TOKEN : ps->tokens.tokens[ps->position + offset];
}

bool _prs_error(const Parser* ps, const u32 start, const u32 len, const char* msg, ...) {
    const SourceError err = {
        .kind = SE_ParserError,
        .message = str_new(msg, strlen(msg)),
        .details = str_null,
        .offset = start,
        .length = len,
    };

    return reporter_push(ps->program->reporter, err, *ps->program->source);
}

bool _prs_match(Parser* ps, const TokenType type) {
    if (_prs_current(ps).type != type)
        return false;

    ps->position++;
    return true;
}

bool _prs_expect(Parser* ps, const TokenType type, const char* msg, ...) {
    if (_prs_match(ps, type))
        return false;

    const Token current = _prs_current(ps);
    _prs_error(ps, current.start, current.lexeme.length, msg);
    return true;
}

bool _prs_is(const Parser* ps, const TokenType type) {
    return _prs_current(ps).type != type;
}

Token _prs_advance(Parser* ps) {
    const Token current = _prs_current(ps);
    if (!_prs_isAtEnd(ps))
        ps->position++;

    return current;
}

Token _prs_skip(Parser* ps, const u32 count) {
    const Token current = _prs_current(ps);
    if (!_prs_isAtEnd(ps))
        ps->position += count;

    return current;
}

AstNode _prs_expression(Parser* ps);

AstNode _prs_parseDecl(Parser* ps) {
    const u32 start = ps->position;

    str_t name = str_null;
    if (_prs_is(ps, tt_identifier))
        name = _prs_advance(ps).lexeme;

    if (_prs_expect(ps, tt_colon, "Expected ':'"))
        return AstNode_NULL;

    AstNode expr = _prs_expression(ps);

    if (node_isNull(&expr))
        return AstNode_NULL;

    // TODO: return decl node
    return AstNode_NULL;
}

AstNode _prs_expression(Parser* ps) {
    return (AstNode){ 0 };
}