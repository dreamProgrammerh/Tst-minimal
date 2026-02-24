#pragma once

#include "ast.h"

static inline
u32 ast_makeRoot(AstArena* arena, const u32* decls, const u32 count, const u32 startPos) {
    const u32 index = ast_addNode(arena, NODE_ROOT, startPos);
    arena->nodes[index].data = count;  // Store declaration count

    for (u32 i = 0; i < count; i++) {
        ast_addChild(arena, index, decls[i]);
    }

    return index;
}

static inline
u32 ast_makeDecl(AstArena* arena, const u32 identName, const u32 value, const u32 startPos) {
    const u32 index = ast_addNode(arena, NODE_DECL, startPos);

    ast_addChild(arena, index, identName);
    ast_addChild(arena, index, value);

    return index;
}

static inline
u32 ast_makeInt(AstArena* arena, const i32 value, const u32 startPos) {
    const u32 index = ast_addNode(arena, NODE_LIT_INT, startPos);
    arena->nodes[index].data = (u32)value;  // Store integer value directly
    return index;
}

static inline
u32 ast_makeFloat(AstArena* arena, const f32 value, const u32 startPos) {
    const u32 index = ast_addNode(arena, NODE_LIT_FLOAT, startPos);
    // Store float bits in data
    const union { f32 f; u32 u; } converter = { .f = value };
    arena->nodes[index].data = converter.u;
    return index;
}

static inline
u32 ast_makeUnary(AstArena* arena, const OpCode op, const u32 operand, const u32 startPos) {
    const u32 index = ast_addNode(arena, NODE_UNARY, startPos);
    arena->nodes[index].data = op;  // Store operator

    ast_addChild(arena, index, operand);
    return index;
}

static inline
u32 ast_makeBinary(AstArena* arena, const OpCode op,
        const u32 left, const u32 right, const u32 startPos) {
    const u32 index = ast_addNode(arena, NODE_BINARY, startPos);
    arena->nodes[index].data = op;  // Store operator

    ast_addChild(arena, index, left);
    ast_addChild(arena, index, right);
    return index;
}
