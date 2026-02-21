#pragma once

#include "../utils/c23.h"
#include "../utils/short-types.h"
#include "../utils/platform.h"

// String length of
#define slenof(x) (sizeof(x) - 1)

// Array length of
#define lenof(x) (sizeof(x) / sizeof(x[0]))

#define CL_whitespaces " \t\v\r\f\n"
#define CL_newline OS_NEWLINE

#define CL_LineComment "//"
#define CL_BlockCommentStart "/*"
#define CL_BlockCommentEnd "*/"

#define CL_NumberSeparator '_'

#define CL_RotateLeft "<<<"
#define CL_RotateRight ">>>"
#define CL_ShiftLeft "<<"
#define CL_ShiftRight ">>"
#define CL_IntDiv "/%"
#define CL_Power "**"
#define CL_StrictEqual "==="
#define CL_StrictNotEqual "!=="
#define CL_ApproxEqual "~=="
#define CL_NotApproxEqual "!~="
#define CL_EqualEqual "=="
#define CL_NotEqual "!="
#define CL_LessEqual "<="
#define CL_GreaterEqual ">="
#define CL_LogicalAnd "&&"
#define CL_LogicalOr "||"
#define CL_LogicalXor "^^"
#define CL_Coalesce "??"
#define CL_Guard "!!"
#define CL_Dollar '$'
#define CL_BitAnd '&'
#define CL_BitOr '|'
#define CL_BitXor '^'
#define CL_BitNot '~'
#define CL_Plus '+'
#define CL_Minus '-'
#define CL_Star '*'
#define CL_Slash '/'
#define CL_Percent '%'
#define CL_LParen '('
#define CL_RParen ')'
#define CL_Comma ','
#define CL_Less '<'
#define CL_Greater '>'
#define CL_Not '!'
#define CL_Question '?'
#define CL_Colon ':'
#define CL_Semicolon ';'
#define CL_Hash '#'

static const
char CL_Operators1[] = {
    CL_Dollar,
    CL_BitAnd,
    CL_BitOr,
    CL_BitXor,
    CL_BitNot,
    CL_Plus,
    CL_Minus,
    CL_Star,
    CL_Slash,
    CL_Percent,
    CL_LParen,
    CL_RParen,
    CL_Comma,
    CL_Less,
    CL_Greater,
    CL_Not,
    CL_Question,
    CL_Colon,
    CL_Semicolon,
    CL_Hash,
};

static const
char* CL_Operators2[] = {
  CL_ShiftLeft,
  CL_ShiftRight,
  CL_IntDiv,
  CL_Power,
  CL_EqualEqual,
  CL_NotEqual,
  CL_LessEqual,
  CL_GreaterEqual,
  CL_LogicalAnd,
  CL_LogicalOr,
  CL_LogicalXor,
  CL_Coalesce,
  CL_Guard,
};

static const
char* CL_Operators3[] = {
  CL_RotateLeft,
  CL_RotateRight,
  CL_StrictEqual,
  CL_StrictNotEqual,
  CL_ApproxEqual,
  CL_NotApproxEqual,
};

static inline
bool CL_isWhitespace(const char c) {
    return c == ' ' || c == '\t' || c == '\v' || c == '\r' || c == '\f' || c == '\n';
}

static inline
bool CL_isOperator(const char c) {
    for (u16 i = 0; i < lenof(CL_Operators1); i++) {
        if (CL_Operators1[i] == c)
            return true;
    }

    for (u16 i = 0; i < lenof(CL_Operators2); i++) {
        if (CL_Operators2[i][0] == c)
            return true;
    }

    for (u16 i = 0; i < lenof(CL_Operators3); i++) {
        if (CL_Operators3[i][0] == c)
            return true;
    }

    return false;
}

static inline
bool CL_isAlpha(const char c) {
    return 'a' <= (c | 32) && (c | 32) <= 'z';
}

static inline
bool CL_isDigit(const char c) {
    return '0' <= c && c <= '9';
}

static inline
bool CL_isIdentifierStart(const char c) {
    return CL_isAlpha(c) || c == '_';
}

static inline
bool CL_isIdentifierPart(const char c) {
    return CL_isAlpha(c) || CL_isDigit(c) || c == '_';
}

static inline
bool CL_isNumberStart(const char c) {
    return CL_isDigit(c) || c == '.';
}

static inline
bool CL_isValidNumberBreak(const char c) {
  return CL_isWhitespace(c) || CL_isOperator(c);
}

static inline
bool CL_isOctDigit(const char c) {
    return '0' <= c && c <= '7';
}

static inline
bool CL_isBinDigit(const char c) {
    return c == '0' || c == '1';
}

static inline
bool CL_isHexDigit(const char c) {
    return CL_isDigit(c) || ('a' <= (c | 32) && (c | 32) <= 'f');
}

static inline
bool CL_isMaskDigit(const char c) {
    return CL_isDigit(c) || c == 'i' || c == 'I' || c == 'o' || c == 'O' || c == 'r' || c == 'R';
}