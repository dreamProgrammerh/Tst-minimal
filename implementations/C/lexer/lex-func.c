#pragma once

#include <stdlib.h>

#include "token.h"
#include "lexer.h"
#include "../constants/const-lexer.h"

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// LEXER HELPERS
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

bool _lex_isAtEnd(const Lexer* lx) {
    return lx->position >= lx->src.length;
}

char _lex_current(const Lexer* lx) {
    return _lex_isAtEnd(lx) ? '\0' : lx->src.data[lx->position];;
}

char _lex_peek(const Lexer* lx, const u32 offset) {
    return (lx->position + offset >= lx->src.length)
        ? '\0' : lx->src.data[lx->position + offset];;
}

bool _lex_error(Lexer* lx, const u32 start, const u32 len, char* msg, ...) {
  return false;
}

bool _lex_match(Lexer* lx, const char* s, const u32 len) {
    for (u32 i = 0; i < len; i++) {
        if (lx->src.data[lx->position + i] != s[i])
            return false;
    }
    
    lx->position += len;
    return true;
}

bool _lex_is(const Lexer* lx, const char* s, const u32 len) {
    for (u32 i = 0; i < len; i++) {
        if (lx->src.data[lx->position + i] != s[i])
            return false;
    }

    return true;
}

bool _lex_advance(Lexer* lx, const u32 len) {
    if (!_lex_isAtEnd(lx))
        lx->position += len;

    return !_lex_isAtEnd(lx);
}

#define _lex_matcha(lx, s) _lex_match(lx, s, slenof(s))
#define _lex_isa(lx, s) _lex_is(lx, s, slenof(s))
#define _lex_advancea(lx, s) _lex_advance(lx, slenof(s))

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// LEXER SKIP HELPERS
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

void _lex_skipWhitespace(Lexer* lx) {
    while (!_lex_isAtEnd(lx) && CL_isWhitespace(_lex_current(lx)))
        lx->position++;
}

void _lex_skipLineComment(Lexer* lx) {
    while (_lex_matcha(lx, CL_LineComment)) {
        while (!(_lex_isAtEnd(lx) || _lex_matcha(lx, CL_newline)))
            lx->position++;
    }
}

void _lex_skipBlockComment(Lexer* lx) {
    while (_lex_matcha(lx, CL_BlockCommentStart)) {
        while (!(_lex_isAtEnd(lx) || _lex_matcha(lx, CL_BlockCommentEnd)))
            lx->position++;
    }
}

void _lex_skipComment(Lexer* lx) {
    while (_lex_isa(lx, CL_LineComment) || _lex_isa(lx, CL_BlockCommentStart)) {
        _lex_skipLineComment(lx);
        _lex_skipBlockComment(lx);
        _lex_skipWhitespace(lx);
    }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// LEXER TOKENIZE
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Token _lex_color(Lexer* lx);
Token _lex_identifier(Lexer* lx);
Token _lex_number(Lexer* lx);

Token _lex_nextTok(Lexer* lx) {
    _lex_skipWhitespace(lx);
    _lex_skipComment(lx);

    if (_lex_isAtEnd(lx)) return INVALID_TOKEN;
    const char c = _lex_current(lx);
    const u32 start = lx->position;

    char* cstr = malloc(2);
    cstr[0] = c;
    cstr[1] = '\0';

    const str_t lexeme = (str_t) { .data = cstr, .length = 1};

#define ifMatch(s) if (_lex_matcha(lx, s))
#define tokenof(type) tok_new(type, lexeme, start)

    if (CL_isNumberStart(c))
        return _lex_number(lx);

    if (CL_isIdentifierStart(c))
        return _lex_identifier(lx);

    if (CL_isWhitespace(_lex_peek(lx, 1)))
        goto Single;

    if (CL_isWhitespace(_lex_peek(lx, 2)))
        goto Double;

    // Handle triple char operators
    ifMatch (CL_RotateLeft)
        return tokenof(tt_rotLeft);

    ifMatch (CL_RotateRight)
        return tokenof(tt_rotRight);

    ifMatch (CL_StrictEqual)
        return tokenof(tt_strictEqual);

    ifMatch (CL_StrictNotEqual)
        return tokenof(tt_strictNotEqual);

    ifMatch (CL_ApproxEqual)
        return tokenof(tt_approxEqual);

    ifMatch (CL_NotApproxEqual)
        return tokenof(tt_notApproxEqual);

    // Handle double char operators
Double:
    ifMatch (CL_ShiftLeft)
        return tokenof(tt_shiftLeft);

    ifMatch (CL_ShiftRight)
        return tokenof(tt_shiftRight);

    ifMatch (CL_IntDiv)
        return tokenof(tt_intDiv);

    ifMatch (CL_Power)
        return tokenof(tt_power);

    ifMatch (CL_EqualEqual)
        return tokenof(tt_equalEqual);

    ifMatch (CL_NotEqual)
        return tokenof(tt_notEqual);

    ifMatch (CL_LessEqual)
        return tokenof(tt_lessEqual);

    ifMatch (CL_GreaterEqual)
        return tokenof(tt_greaterEqual);

    ifMatch (CL_LogicalAnd)
        return tokenof(tt_logicalAnd);

    ifMatch (CL_LogicalOr)
        return tokenof(tt_logicalOr);

    ifMatch (CL_LogicalXor)
        return tokenof(tt_logicalXor);

    ifMatch (CL_Coalesce)
        return tokenof(tt_coalesce);

    ifMatch (CL_Guard)
        return tokenof(tt_guard);

    // Handle single char operators
Single:
    switch (c) {
        case CL_Dollar:
            return tokenof(tt_dollar);

        case CL_BitAnd:
            return tokenof(tt_bitAnd);

        case CL_BitOr:
            return tokenof(tt_bitOr);

        case CL_BitXor:
            return tokenof(tt_bitXor);

        case CL_BitNot:
            return tokenof(tt_bitNot);

        case CL_Plus:
            return tokenof(tt_plus);

        case CL_Minus:
            return tokenof(tt_minus);

        case CL_Star:
            return tokenof(tt_star);

        case CL_Slash:
            return tokenof(tt_slash);

        case CL_Percent:
            return tokenof(tt_percent);

        case CL_LParen:
            return tokenof(tt_lParen);

        case CL_RParen:
            return tokenof(tt_rParen);

        case CL_Comma:
            return tokenof(tt_comma);

        case CL_Less:
            return tokenof(tt_less);

        case CL_Greater:
            return tokenof(tt_greater);

        case CL_Not:
            return tokenof(tt_not);

        case CL_Question:
            return tokenof(tt_question);

        case CL_Colon:
            return tokenof(tt_colon);

        case CL_Semicolon:
            return tokenof(tt_semicolon);

        case CL_Hash:
            free(cstr);
            return _lex_color(lx);

        default:;
    }

#undef ifMatch
#undef tokenof

    _lex_error(lx, lx->position, 1,
        "Unexpected character: '%c'", c);

    lx->position++;
    return INVALID_TOKEN;
}

Token _lex_color(Lexer* lx) {
    const u32 start = lx->position;
    _lex_advancea(lx, CL_Hash);

    while (!_lex_isAtEnd(lx)
        && CL_isHexDigit(lx->src.data[lx->position]))
        lx->position++;

    const u32 lexLength = lx->position - start;
    char* lexeme = malloc(lexLength + 1);

    for (u32 i = 0; i < lexLength; i++)
        lexeme[lexLength - i] = lx->src.data[lx->position - i];

    lexeme[lexLength] = '\0';

    return tok_new(tt_hexColor,
        (str_t){ .data=lexeme, .length=lexLength }, start);
}

Token _lex_identifier(Lexer* lx) {
    const u32 start = lx->position;

    while (!_lex_isAtEnd(lx)
        && CL_isIdentifierPart(lx->src.data[lx->position]))
        lx->position++;

    const u32 lexLength = lx->position - start;
    char* lexeme = malloc(lexLength + 1);

    for (u32 i = 0; i < lexLength; i++)
        lexeme[lexLength - i] = lx->src.data[lx->position - i];

    lexeme[lexLength] = '\0';

    return tok_new(tt_identifier,
        (str_t){ .data=lexeme, .length=lexLength }, start);
}

Token _lex_number(Lexer* lx) { // TODO
    return INVALID_TOKEN;
}