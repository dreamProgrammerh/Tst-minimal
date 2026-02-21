#pragma once

#include "../utils/short-types.h"
#include "../utils/convert.h"
#include "../utils/strings.h"
#include <stdio.h>
#include <string.h>

// =================================================
// TOKEN TYPE
// =================================================

typedef enum TokenType {
  tt_int32, tt_float32, tt_hex, tt_bin, tt_oct, tt_mask, tt_exp,
  tt_hexColor, tt_identifier, tt_dollar,

  tt_plus, tt_minus, tt_star, tt_slash, tt_percent, tt_intDiv, tt_power,
  tt_bitAnd, tt_bitOr, tt_bitXor, tt_bitNot,
  tt_shiftLeft, tt_shiftRight, tt_rotLeft, tt_rotRight,
  tt_question, tt_colon, tt_semicolon,

  tt_not, tt_equalEqual, tt_notEqual,
  tt_strictEqual, tt_strictNotEqual, tt_approxEqual, tt_notApproxEqual,
  tt_less, tt_greater, tt_lessEqual, tt_greaterEqual,

  tt_logicalAnd, tt_logicalOr, tt_logicalXor,
  tt_coalesce, tt_guard,

  tt_lParen, tt_rParen, tt_comma,
  tt_invalid, tt_eof
} TokenType;

static const
char* TokenType_names[] = {
    "int32", "float32", "hex", "bin", "oct", "mask", "exp",
    "hexColor", "identifier", "dollar",

    "plus", "minus", "star", "slash", "percent", "intDiv", "power",
    "bitAnd", "bitOr", "bitXor", "bitNot",
    "shiftLeft", "shiftRight", "rotLeft", "rotRight",
    "question", "colon", "semicolon",

    "not", "equalEqual", "notEqual",
    "strictEqual", "strictNotEqual", "approxEqual", "notApproxEqual",
    "less", "greater", "lessEqual", "greaterEqual",

    "logicalAnd", "logicalOr", "logicalXor",
    "coalesce", "guard",

    "lParen", "rParen", "comma",
    "invalid", "eof"
};

// =================================================
// TOKEN
// =================================================

typedef struct Token {
  str_t lexeme;
  u32 start;
  TokenType type;
} Token;

static Token INVALID_TOKEN = (Token){
    .lexeme = { .data = NULL, .length = 0 },
    .start = 0, .type = tt_invalid
};

static inline
Token tok_new(const TokenType type, const str_t lexeme, const u32 start) {
    return (Token){ .lexeme = lexeme, .start = start, .type = type };
}

static inline
u32 tok_len(const Token token) {
    return token.lexeme.length;
}

static inline
u32 tok_start(const Token token) {
    return token.start;
}

static inline
u32 tok_end(const Token token) {
    return token.start + token.lexeme.length;
}

static inline
i32 tok_asInt(const Token token) {
    switch (token.type) {
      case tt_int32:
        return cvt_decimalToInt(token.lexeme.data, token.lexeme.length);
        
      case tt_hexColor:
        bool _;
        return (i32)cvt_hexStrToColor(token.lexeme.data, token.lexeme.length, &_);
        
      case tt_hex:
        return cvt_hexToInt(token.lexeme.data, token.lexeme.length);
        
      case tt_oct:
        return cvt_octToInt(token.lexeme.data, token.lexeme.length);

      case tt_mask:
        return (i32)cvt_maskToInt(token.lexeme.data, token.lexeme.length);

      case tt_bin:
        return cvt_binToInt(token.lexeme.data, token.lexeme.length);
      
      default:
        return 0;
    }
}

static inline
float tok_asFloat(const Token token) {
    switch (token.type) {
      case tt_float32:
        return cvt_floatToFloat(token.lexeme.data, token.lexeme.length);

      case tt_exp:
        return cvt_expToFloat(token.lexeme.data, token.lexeme.length);

      default:
        return 0.0f;
    }
}

static inline
str_t tok_toString(const Token token) {
    char buf[128];

    const i32 len = snprintf(buf, sizeof(buf),
        "%s('%s')", TokenType_names[token.type], token.lexeme.data);

    return (str_t){ .data = strdup(buf), .length = (u32)len };
}

// =================================================
// TOKENS LIST
// =================================================

typedef struct TokenList {
    void* (*alloc)(usize);
    void (*free)(void*);
    Token* tokens;
    usize length;
    usize capacity;
} TokenList;

static inline
TokenList* toklist_new(const usize capacity,
    void* (*allocFn)(usize),
    void (*freeFn)(void*)) {
    TokenList* tl = allocFn(sizeof(TokenList));
    if (tl == NULL) return NULL;

    tl->tokens = allocFn(capacity * sizeof(Token));
    if (tl->tokens == NULL) {
        freeFn(tl);
        return NULL;
    }

    tl->length = 0;
    tl->capacity = capacity;
    tl->alloc = allocFn;
    tl->free = freeFn;

    return tl;
}

static inline
bool toklist_init(TokenList* tl) {
    tl->tokens = tl->alloc(tl->capacity * sizeof(Token));
    if (tl->tokens == NULL) return false;

    tl->length = 0;
    return true;
}

static inline
void toklist_free(TokenList* tl) {
    if (tl) {
        if (tl->tokens) tl->free(tl->tokens);
        tl->free(tl);
    }
}

static inline
bool _toklist_setCapacity(TokenList* tl, const usize capacity) {
    Token* tokens = tl->alloc(capacity * sizeof(Token));
    if (!tokens) {
        fprintf(stderr, "TokenList Error: Memory allocation failed during reallocation.\n");
        return true;  // Return true on failure for easier checking
    }

    const usize cpylen = tl->length > capacity ? capacity : tl->length;
    memcpy(tokens, tl->tokens, cpylen * sizeof(Token));
    tl->free(tl->tokens);

    tl->tokens = tokens;
    tl->capacity = capacity;
    tl->length = cpylen;  // Ensure length doesn't exceed new capacity
    return false;  // Return false on success
}

static inline
bool _toklist_tryGrow(TokenList* tl) {
    if ((float)tl->length <= (float)tl->capacity * 0.90f) return false;

    const usize new_capacity = (usize)((float)tl->capacity * 1.75f);
    return _toklist_setCapacity(tl, new_capacity);  // returns true on failure
}

static inline
bool _toklist_tryShrink(TokenList* tl) {
    if ((float)tl->length >= (float)tl->capacity * 0.25f) return false;

    const usize new_capacity = (usize)((float)tl->capacity * 0.50f);
    return _toklist_setCapacity(tl, new_capacity);  // returns true on failure
}

static inline
Token* toklist_at(const TokenList* tl, const usize index) {
    if (tl->tokens == NULL || index >= tl->length) return NULL;
    return &tl->tokens[index];  // Return pointer to element
}

static inline
bool toklist_set(const TokenList* tl, const usize index, const Token tok) {
    if (tl->tokens == NULL || index >= tl->length) return false;

    tl->tokens[index] = tok;
    return true;
}

static inline
void toklist_clear(TokenList* tl) {
    if (tl->tokens) {
        tl->free(tl->tokens);
        tl->tokens = NULL;
        tl->length = 0;
        tl->capacity = 0;
    }
}

static inline
bool toklist_push(TokenList* tl, const Token tok) {
    if (tl->tokens == NULL) return false;
    if (_toklist_tryGrow(tl)) return false;  // true on failure

    tl->tokens[tl->length++] = tok;
    return true;
}

static inline
Token toklist_pop(TokenList* tl) {
    if (tl->tokens == NULL || tl->length == 0) return INVALID_TOKEN;

    tl->length--;  // decrement before accessing
    const Token tok = tl->tokens[tl->length];
    _toklist_tryShrink(tl);
    return tok;
}