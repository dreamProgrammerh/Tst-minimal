#pragma once

#include "strings.h"

extern str_t scriptPath;        // Entry point path
extern str_t scriptName;        // File name of entry point
extern str_t scriptDirectory;   // Directory of entry point
extern str_t absRunPath;        // The current absolute path at '.'

// Initialize all globals from main
void initGlobals(int argc, char* argv[]);

// Log globals to terminal
void logGlobals();

// Clean up any allocated memory
void cleanupGlobals(void);