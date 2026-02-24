/*
 * @file ast.h
 *
 * Minimal, flatten bytecode-oriented AST
 */

#pragma once

#include "../utils/short-types.h"

// TODO: define ast nodes flags
// #define NODE_FLAG_CONST (1u << 0) ...

typedef enum NodeKind NodeKind;
typedef enum OpCode OpCode;
typedef struct AstNode AstNode;
typedef struct AstArena AstArena;

// Node types
enum NodeKind {
    NODE_ROOT,          // Program root
    NODE_DECL,          // Variable declaration

    NODE_IDENT,         // Identifier
    NODE_LIT_INT,       // Integers
    NODE_LIT_FLOAT,     // Floats
    NODE_LIT_BOOL,      // Booleans

    NODE_UNARY,         // -x, !x
    NODE_BINARY,        // + - * / % /% ** & && | || ^ ^^ etc
    NODE_TERNARY,       // ... ? ... : ...
    NODE_CALL,          // Function call
    NODE_ACCESS,        // Variable access
    NODE_ASSIGN,        // Assignment
};

enum OpCode {
    // Unary
    OP_NEG, OP_NOT,

    // Binary
    OP_ADD, OP_SUB,
    OP_MUL, OP_DIV,
    OP_EQ, OP_NEQ,
    OP_AEQ, OP_NAEQ,
    OP_SEQ, OP_NSEQ,
    OP_LT, OP_GT,
    OP_LE, OP_GE,
    OP_AND, OP_OR,
    OP_XOR, OP_LXOR,
    OP_LAND, OP_LOR,
    OP_SHL, OP_SHR,
    OP_ROL, OP_ROR,
};

struct AstNode {
    u16 kind;           // 2 bytes
    u16 flags;          // 2 bytes (constant, used, etc.)
    u32 firstChild;     // Index into children array
    u8 childLength;     // Size of node children
    u32 data;           // Integer literal or string index
    u32 sourcePos;      // For error reporting
};

struct AstArena {
    AstNode* nodes;         // Flat array of nodes
    u32* children;          // Child indices
    u32 nodeCapacity;
    u32 nodeLength;
    u32 childCapacity;
    u32 childLength;
};

AstArena ast_new(u32 nodeCapacity, u32 childCapacity);
void ast_release(const AstArena* ast);

u32 ast_addNode(AstArena* a, NodeKind kind, u32 startPos);
void ast_addChild(AstArena *a, u32 parentIndex, u32 childIndex);

AstNode* ast_getNode(const AstArena *a, u32 idx);
u32 ast_getChild(const AstArena *a, u32 idx);
