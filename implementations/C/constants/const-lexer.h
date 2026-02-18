#pragma once

#include "../utils/c23.h"
#include "../utils/short-types.h"
#include "../utils/platform.h"

// String length of
#define slenof(x) (sizeof(x) - 1)

// Array length of
#define lenof(x) (sizeof(x) / sizeof(x[0]))

final char CL_whitespaces[] = " \t\v\r\f\n";
final char CL_newline[2] = OS_NEWLINE;

final char CL_LineComment[2] = "//";
final char CL_BlockCommentStart[2] = "/*";
final char CL_BlockCommentEnd[2] = "*/";

final char CL_NumberSeparator = '_';

final char CL_RotateLeft[3] = "<<<";
final char CL_RotateRight[3] = ">>>";
final char CL_ShiftLeft[2] = "<<";
final char CL_ShiftRight[2] = ">>";
final char CL_IntDiv[2] = "/%";
final char CL_Power[2] = "**";
final char CL_StrictEqual[3] = "===";
final char CL_StrictNotEqual[3] = "!==";
final char CL_ApproxEqual[3] = "~==";
final char CL_NotApproxEqual[3] = "!~=";
final char CL_EqualEqual[2] = "==";
final char CL_NotEqual[2] = "!=";
final char CL_LessEqual[2] = "<=";
final char CL_GreaterEqual[2] = ">=";
final char CL_LogicalAnd[2] = "&&";
final char CL_LogicalOr[2] = "||";
final char CL_LogicalXor[2] = "^^";
final char CL_Coalesce[2] = "??";
final char CL_Guard[2] = "!!";
final char CL_Dollar = '$';
final char CL_BitAnd = '&';
final char CL_BitOr = '|';
final char CL_BitXor = '^';
final char CL_BitNot = '~';
final char CL_Plus = '+';
final char CL_Minus = '-';
final char CL_Star = '*';
final char CL_Slash = '/';
final char CL_Percent = '%';
final char CL_LParen = '(';
final char CL_RParen = ')';
final char CL_Comma = ',';
final char CL_Less = '<';
final char CL_Greater = '>';
final char CL_Not = '!';
final char CL_Question = '?';
final char CL_Colon = ':';
final char CL_Semicolon = ';';
final char CL_Hash = '#';

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