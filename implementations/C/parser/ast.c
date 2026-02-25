#include "ast.h"

#include <stdlib.h>

static inline
void _ast_tryGrowNodes(AstArena* a) {
    if (a->nodeLength >= a->nodeCapacity) {
        a->nodeCapacity *= 2;
        a->nodes = realloc(a->nodes, a->nodeCapacity);
    }
}

static inline
void _ast_tryGrowChildren(AstArena* a) {
    if (a->childLength >= a->childCapacity) {
        a->childCapacity *= 2;
        a->children = realloc(a->children, sizeof(u32) * a->childCapacity);
    }
}

AstArena ast_new(const u32 nodeCapacity, const u32 childCapacity) {
    AstArena a = {
        .nodeCapacity = nodeCapacity,
        .childCapacity = childCapacity,
        .nodes = NULL,
        .children = NULL,
    };

    a.nodes = malloc(sizeof(AstNode) * nodeCapacity);
    a.children = malloc(sizeof(u32) * childCapacity);
    return a;
}

void ast_release(const AstArena* ast) {
    free(ast->nodes);
    free(ast->children);
}

NodeId ast_addNode(AstArena* a, const NodeKind kind, const u32 startPos) {
    _ast_tryGrowNodes(a);

    const u32 idx = a->nodeLength++;
    AstNode *n = &a->nodes[idx];

    n->kind = kind;
    n->flags = 0;
    n->firstChild = a->childLength;  // Will be updated
    n->childLength = 0;
    n->data = 0;
    n->sourcePos = startPos;

    return idx;
}

void ast_addChild(AstArena *a, const NodeId parentId, const NodeId childId) {
    _ast_tryGrowChildren(a);

    AstNode *parent = &a->nodes[parentId];
    if (parent->childLength == 0) {
        parent->firstChild = a->childLength;
    }

    a->children[a->childLength++] = childId;
    parent->childLength++;
}

AstNode* ast_getNode(const AstArena *a, const NodeId id) {
    if (id >= a->nodeLength) return NULL;
    return &a->nodes[id];
}

NodeId ast_getChild(const AstArena *a, const ChildId id) {
    if (id >= a->childLength) return UINT32_MAX;
    return a->children[id];
}