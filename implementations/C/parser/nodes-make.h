#pragma once

#include "ast.h"

static inline
NodeId ast_makeRoot(AstArena* arena, const u32* decls, const u32 count, const u32 startPos) {
    const NodeId id = ast_addNode(arena, NODE_ROOT, startPos);
    arena->nodes[id].data = count;  // Store declaration count

    for (u32 i = 0; i < count; i++) {
        ast_addChild(arena, id, decls[i]);
    }

    return id;
}

static inline
NodeId ast_makeDecl(AstArena* arena, const u32 identName, const u32 value, const u32 startPos) {
    const NodeId id = ast_addNode(arena, NODE_DECL, startPos);

    ast_addChild(arena, id, identName);
    ast_addChild(arena, id, value);

    return id;
}

static inline
NodeId ast_makeInt(AstArena* arena, const i32 value, const u32 startPos) {
    const NodeId id = ast_addNode(arena, NODE_LIT_INT, startPos);
    arena->nodes[id].data = (u32)value;  // Store integer value directly
    return id;
}

static inline
NodeId ast_makeFloat(AstArena* arena, const f32 value, const u32 startPos) {
    const NodeId id = ast_addNode(arena, NODE_LIT_FLOAT, startPos);
    // Store float bits in data
    const union { f32 f; u32 u; } converter = { .f = value };
    arena->nodes[id].data = converter.u;
    return id;
}

static inline
NodeId ast_makeUnary(AstArena* arena, const OpCode op, const u32 operand, const u32 startPos) {
    const NodeId id = ast_addNode(arena, NODE_UNARY, startPos);
    arena->nodes[id].data = op;  // Store operator

    ast_addChild(arena, id, operand);
    return id;
}

static inline
NodeId ast_makeBinary(AstArena* arena, const OpCode op,
        const u32 left, const u32 right, const u32 startPos) {
    const NodeId id = ast_addNode(arena, NODE_BINARY, startPos);
    arena->nodes[id].data = op;  // Store operator

    ast_addChild(arena, id, left);
    ast_addChild(arena, id, right);
    return id;
}
