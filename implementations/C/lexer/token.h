#pragma once

#include "../utils/short-types.h"
#include "../utils/strings.h"
#include <stdio.h>
#include <string.h>

// =================================================
// TOKEN TYPE
// =================================================

typedef enum TokenType {
  tt_int32, tt_float32, tt_hex, tt_bin, tt_oct,
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

static inline // TODO: complete this
i32 tok_asInt(const Token token) {
    switch (token.type) {
      case tt_int32:
        return 1;
        
      case tt_hexColor:
        return 1;
        
      case tt_hex:
        return 1;
        
      case tt_oct:
        return 1;
        
      case tt_bin:
        return 1;
      
      default:
        return 0;
    }
}

static inline // TODO: complete this
float tok_asFloat(const Token token) {
    switch (token.type) {
      case tt_float32:
        return 1.0;
        
      default:
        return 0.0;
    }
}

static inline // TODO: complete this
str_t tok_toString(const Token token) {
    // "${token.type.name}(${token.lexeme.data})"
    return (str_t){ .data = NULL, .length = 0 };
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
TokenList* toklist_new(usize capacity,
    void* (*alloc)(usize),
    void (*free)(void*)) {
    TokenList* tl = alloc(sizeof(*tl));
    if (tl == NULL) return NULL;
    
    tl->tokens = alloc(capacity * sizeof(void*));
    if (tl->tokens == NULL) {
        tl->free(tl);
        return NULL;
    }
    
    tl->length = 0;
    tl->capacity = capacity;
    tl->alloc = alloc;
    tl->free = free;
    
    return tl;
}

static inline
bool toklist_init(TokenList* tl) {
    tl->tokens = tl->alloc(tl->capacity * sizeof(void*));
    if (tl->tokens == NULL) return false;
    
    tl->length = 0;
    return true;
}

static inline
void toklist_free(TokenList* tl) {
    tl->free(tl->tokens);
    tl->free(tl);
}

static inline
bool _toklist_setCapacity(TokenList* tl, usize capacity) {
    Token* tokens = tl->alloc(capacity);
    if (!tokens) {
        printf("TokenList Error: Memory allocation failed during growing.\n");
        return 1;
    }
    
    const usize cpylen = tl->length > capacity ? capacity : tl->length;
    memcpy(tl->tokens, tokens, cpylen * sizeof(Token));
    tl->free(tl->tokens);
    
    tl->tokens = tokens;
    tl->capacity = capacity;
    return 0;
}

static inline
bool _toklist_tryGrow(TokenList* tl) {
    // Grow if length > 90% of capacity
    if (tl->length <= tl->capacity * 0.90) return false;
    
    // Grow by 75% of the current capacity
    const u32 new_capacity = tl->capacity * 1.75;

    if (_toklist_setCapacity(tl, new_capacity))
        return false;

    return true;
}

static inline
bool _toklist_tryShrink(TokenList* tl) {
    // Shrink if length < 25% of capacity
    if (tl->length >= tl->capacity * 0.25) return false;
    
    // Shrink by 50% of the current capacity
    const u32 new_capacity = tl->capacity * 0.50;

    if (_toklist_setCapacity(tl, new_capacity))
        return false;

    return true;
}

static inline
Token* toklist_at(TokenList* tl, u32 index) {
    if (tl->tokens == NULL || index >= tl->length) return NULL;

    return tl->tokens + index;
}

static inline
bool toklist_set(TokenList* tl, u32 index, const Token tok) {
    if (tl->tokens == NULL || index >= tl->length) return false;
    
    tl->tokens[index] = tok;
    return true;
}

static inline
void toklist_clear(TokenList* tl) {
    if (tl->tokens) {
        tl->free(tl->tokens);
        tl->tokens = NULL;
    }
}

static inline
bool toklist_push(TokenList* tl, const Token tok) {
    if (tl->tokens == NULL) return false;
    _toklist_tryGrow(tl);

    tl->tokens[tl->length++] = tok;
    return true;
}

static inline
Token toklist_pop(TokenList* tl) {
    if (tl->tokens == NULL || tl->length == 0) return INVALID_TOKEN;

    const Token tok = tl->tokens[tl->length--];
    _toklist_tryShrink(tl);
    return tok;
}
