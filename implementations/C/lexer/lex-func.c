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

bool _lex_error(Lexer* lx, char* msg, u32 start, u32 len) {
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

Token _lex_hex(Lexer* lx);

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

    switch (c) {
        case CL_Dollar:
            return tok_new(tt_dollar, lexeme, start);

        case CL_BitAnd:
            return tok_new(tt_bitAnd, lexeme, start);

        case CL_BitOr:
            return tok_new(tt_bitOr, lexeme, start);

        case CL_BitXor:
            return tok_new(tt_bitXor, lexeme, start);

        case CL_BitNot:
            return tok_new(tt_bitNot, lexeme, start);

        case CL_Plus:
            return tok_new(tt_plus, lexeme, start);

        case CL_Minus:
            return tok_new(tt_minus, lexeme, start);

        case CL_Star:
            return tok_new(tt_star, lexeme, start);

        case CL_Slash:
            return tok_new(tt_slash, lexeme, start);

        case CL_Percent:
            return tok_new(tt_percent, lexeme, start);

        case CL_LParen:
            return tok_new(tt_lParen, lexeme, start);

        case CL_RParen:
            return tok_new(tt_rParen, lexeme, start);

        case CL_Comma:
            return tok_new(tt_comma, lexeme, start);

        case CL_Less:
            return tok_new(tt_less, lexeme, start);

        case CL_Greater:
            return tok_new(tt_greater, lexeme, start);

        case CL_Not:
            return tok_new(tt_not, lexeme, start);

        case CL_Question:
            return tok_new(tt_question, lexeme, start);

        case CL_Colon:
            return tok_new(tt_colon, lexeme, start);

        case CL_Semicolon:
            return tok_new(tt_semicolon, lexeme, start);

        case CL_Hash:
            free(cstr);
            return _lex_hex(lx);

        default:;
    }

    lx->position++;
    return INVALID_TOKEN;
}

Token _lex_hex(Lexer* lx) {
    return INVALID_TOKEN;
}