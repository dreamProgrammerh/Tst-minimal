#pragma once

#include "ast.h"

// Get nodes children
typedef struct {
    u32* indices;
    u32 count;
} AstChildren;

static inline
AstChildren ast_getChildren(const AstArena* arena, const u32 nodeIndex) {
    const AstNode* node = &arena->nodes[nodeIndex];
    const AstChildren children = {
        .indices = &arena->children[node->firstChild],
        .count = node->childLength
    };
    return children;
}

// Get child at index
static inline
u32 ast_getChildOf(const AstArena* arena, const u32 nodeIndex, const u32 childIndex) {
    const AstNode* node = &arena->nodes[nodeIndex];
    if (childIndex >= node->childLength) return (u32)-1;
    return arena->children[node->firstChild + childIndex];
}

// Get node kind
static inline
NodeKind ast_getKind(const AstArena* arena, const u32 nodeIndex) {
    return arena->nodes[nodeIndex].kind;
}

// Get node data (varies by kind)
static inline
u32 ast_getData(const AstArena* arena, const u32 nodeIndex) {
    return arena->nodes[nodeIndex].data;
}

// Get integer value (assert kind == NODE_INT)
static inline
i32 ast_getInt(const AstArena* arena, const u32 nodeIndex) {
    return (i32)arena->nodes[nodeIndex].data;
}

// Get float value (assert kind == NODE_FLOAT)
static inline
f32 ast_getFloat(const AstArena* arena, const u32 nodeIndex) {
    const union { u32 u; f32 f; } converter = { .u = arena->nodes[nodeIndex].data };
    return converter.f;
}