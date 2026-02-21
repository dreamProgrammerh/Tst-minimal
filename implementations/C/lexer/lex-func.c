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
Token _lex_hexNumber(Lexer* lx, u32 start);
Token _lex_binaryNumber(Lexer* lx, u32 start);
Token _lex_octalNumber(Lexer* lx, u32 start);
Token _lex_decimalNumber(Lexer* lx, u32 start);

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

Token _lex_number(Lexer* lx) {
    const u32 start = lx->position;

    // Check for base prefixes
    if (LEXER_CH(lx) == '0' && lx->position + 1 < lx->src.length) {
        // Next character
        const char c = lx->src.data[lx->position + 1];

        switch (c) {
            case 'x': case 'X':
                return _lex_hexNumber(lx, start);

            case 'b': case 'B':
                return _lex_binaryNumber(lx, start);

            case 'o': case 'O':
                return _lex_octalNumber(lx, start);

            default:;
        }
    }

    // Default to decimal (could be integer or float)
    return _lex_decimalNumber(lx, start);
}

Token _lex_hexNumber(Lexer* lx, const u32 start) {
    // Skip '0x' or '0X'
    lx->position += 2;

    if (_lex_isAtEnd(lx) || (CL_isValidNumberBreak(LEXER_CH(lx))
        && LEXER_CH(lx) != CL_NumberSeparator)) {
        _lex_error(lx, start, lx->position - start,
            "Incomplete hex number: expected digits after 0x");
        return INVALID_TOKEN;
    }

    bool separated = false;

    while (!_lex_isAtEnd(lx)) {
        const char c = LEXER_CH(lx);

        if (c == CL_NumberSeparator) {
            if (separated || lx->position + 1 >= lx->src.length) {
                _lex_error(lx, lx->position, 1, "Invalid separator in hex number");
                return INVALID_TOKEN;
            }

            separated = true;
            lx->position++;
            continue;
        }

        if (CL_isHexDigit(c)) {
            separated = false;
            lx->position++;
            continue;
        }

        if (CL_isValidNumberBreak(c))
            break;

        _lex_error(lx, lx->position, 1,
            "Invalid hex digit: '%c'", c);
        return INVALID_TOKEN;
    }

    const u32 lexLength = lx->position - start;
    char* lexeme = malloc(lexLength + 1);

    for (u32 i = 0; i < lexLength; i++)
        lexeme[lexLength - i] = lx->src.data[lx->position - i];

    lexeme[lexLength] = '\0';

    // Must have at least one hex digit after 0x
    if (lexLength <= 2 ||
      !CL_isHexDigit(LEXER_CH(lx))) {
        _lex_error(lx, start, lx->position - start, "Invalid hex number: '%s'", lexeme);
        return INVALID_TOKEN;
      }

    return tok_new(tt_hex,
        (str_t){ .data=lexeme, .length=lexLength }, start);
}

Token _lex_binaryNumber(Lexer* lx, const u32 start) {
    // Skip '0b' or '0B'
    lx->position += 2;

    if (_lex_isAtEnd(lx) || (CL_isValidNumberBreak(LEXER_CH(lx))
        && LEXER_CH(lx) != CL_NumberSeparator)) {
        _lex_error(lx, start, lx->position - start,
            "Incomplete binary number: expected digits after 0b");
        return INVALID_TOKEN;
    }

    bool separated = false;

    while (!_lex_isAtEnd(lx)) {
        const char c = LEXER_CH(lx);

        if (c == CL_NumberSeparator) {
            if (separated || lx->position + 1 >= lx->src.length) {
                _lex_error(lx, lx->position, 1,
                    "Invalid separator in binary number");
                return INVALID_TOKEN;
            }

            separated = true;
            lx->position++;
            continue;
        }

        if (CL_isBinDigit(c)) {
            separated = false;
            lx->position++;
            continue;
        }

        if (CL_isValidNumberBreak(c))
            break;

        _lex_error(lx, lx->position, 1, "Invalid binary digit: %c'", c);
        return INVALID_TOKEN;
    }

    const u32 lexLength = lx->position - start;
    char* lexeme = malloc(lexLength + 1);

    for (u32 i = 0; i < lexLength; i++)
        lexeme[lexLength - i] = lx->src.data[lx->position - i];

    lexeme[lexLength] = '\0';

    // Must have at least one binary digit after 0b
    if (lexLength <= 2 ||
      !CL_isBinDigit(LEXER_CH(lx))) {
        _lex_error(lx, start, lx->position - start, "Invalid binary number: '%s'", lexeme);
        return INVALID_TOKEN;
      }

    return tok_new(tt_bin,
        (str_t){ .data=lexeme, .length=lexLength }, start);
}

Token _lex_octalNumber(Lexer* lx, const u32 start) {
    // Skip '0o' or '0O'
    lx->position += 2;

    if (_lex_isAtEnd(lx) || (CL_isValidNumberBreak(LEXER_CH(lx))
        && LEXER_CH(lx) != CL_NumberSeparator)) {
        _lex_error(lx, start, lx->position - start,
            "Incomplete hex number: expected digits after 0o");
        return INVALID_TOKEN;
    }

    bool separated = false;

    while (!_lex_isAtEnd(lx)) {
        const char c = LEXER_CH(lx);

        if (c == CL_NumberSeparator) {
            if (separated || lx->position + 1 >= lx->src.length) {
                _lex_error(lx, start, lx->position,
                    "Invalid separator in octal number");
                return INVALID_TOKEN;
            }

            separated = true;
            lx->position++;
            continue;
        }

        if (CL_isOctDigit(c)) {
            separated = false;
            lx->position++;
            continue;
        }

        if (CL_isValidNumberBreak(c))
            break;

        _lex_error(lx, lx->position, 1, "Invalid octal digit: '%c'", c);
        return INVALID_TOKEN;

    }

    const u32 lexLength = lx->position - start;
    char* lexeme = malloc(lexLength + 1);

    for (u32 i = 0; i < lexLength; i++)
        lexeme[lexLength - i] = lx->src.data[lx->position - i];

    lexeme[lexLength] = '\0';

    // Must have at least one octal digit after 0o
    if (lexLength <= 2 ||
      !CL_isOctDigit(LEXER_CH(lx))) {
        _lex_error(lx, start, lx->position - start,
            "Invalid octal number: '%s'", lexeme);
        return INVALID_TOKEN;
      }

    return tok_new(tt_oct,
        (str_t){ .data=lexeme, .length=lexLength }, start);
}

Token _lex_decimalNumber(Lexer* lx, const u32 start) {
    bool hasDot = false;
    bool hasExp = false;
    bool separated = false;
    TokenType type = tt_int32;

    // Check if starts with dot
    if (_lex_current(lx) == '.') {
      hasDot = true;
      type = tt_float32;
      lx->position++;
    }

    while (!_lex_isAtEnd(lx)) {
      const char c = LEXER_CH(lx);

      if (c == CL_NumberSeparator) {
        if (separated || lx->position + 1 >= lx->src.length) {
          _lex_error(lx, lx->position, 1,
              "Invalid separator in decimal number");
          return INVALID_TOKEN;
        }

        separated = true;
        lx->position++;
        continue;
      }

      separated = false;

      // Handle decimal point
      if (c == '.') {
        if (hasDot || hasExp) {
          _lex_error(lx, lx->position, 1, "Unexpected decimal point");
          return INVALID_TOKEN;
        }

        hasDot = true;
        type = tt_float32;
        lx->position++;
        continue;
      }

      // Handle exponent
      if (c == 'e' || c == 'E') {
        if (hasExp) {
          _lex_error(lx, lx->position, 1, "Unexpected exponent");
          return INVALID_TOKEN;
        }

        hasExp = true;
        type = tt_float32;
        lx->position++;

        // Optional exponent sign
        if (!_lex_isAtEnd(lx)
            && (LEXER_CH(lx) == '+' || LEXER_CH(lx) == '-'))
          lx->position++;

        continue;
      }

      // if it is a digit, continue parsing
      if (CL_isDigit(c)) {
        lx->position++;
        continue;
      }

      if (CL_isValidNumberBreak(c))
        break;

      _lex_error(lx, lx->position, 1, "Invalid decimal digit: '%c'", c);
      return INVALID_TOKEN;

    }

    const u32 lexLength = lx->position - start;
    char* lexeme = malloc(lexLength + 1);

    for (u32 i = 0; i < lexLength; i++)
        lexeme[lexLength - i] = lx->src.data[lx->position - i];

    lexeme[lexLength] = '\0';

    // Validate the decimal number
    if (lexLength == 0) {
      _lex_error(lx, start, lx->position - start,
          "Empty number literal");
      return INVALID_TOKEN;
    }

    const char last = lx->src.data[lx->position];
    const char oneLast = lx->src.data[lx->position - 1];

    // Ends with dot '.'
    if (hasDot && last == '.') {
      _lex_error(lx, start, lx->position - start,
          "Incomplete decimal number: '%s'", lexeme);
      return INVALID_TOKEN;
    }

    // Ends with exponent 'e?[+-]'
    if (hasExp &&
        (last == 'e' || last == 'E' ||
        ((oneLast == 'e' || oneLast == 'E') &&
        (last == '+' || last == '-')))) {
      _lex_error(lx, start, lx->position - start,
          "Incomplete exponent in: '%s'", lexeme);
      return INVALID_TOKEN;
    }

    return tok_new(type,
        (str_t) { .data=lexeme, .length=lexLength } ,start);
}