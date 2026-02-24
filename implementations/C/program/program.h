#pragma once

#include "../parser/ast.h"
#include "string-pool.h"
#include "source.h"

typedef struct Program {
    AstArena* ast;
    StringPool* stringPool;
    Source* source;
    ErrorReporter* reporter;
} Program;

