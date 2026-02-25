#include "globals.h"
#include <stdlib.h>
#include <stdio.h>

#ifdef _WIN32
    #include <windows.h>
    #include <direct.h>
    #define _G_PATH_MAX MAX_PATH
    #define getcwd _getcwd
#else
    #include <unistd.h>
    #include <limits.h>
#endif

// Define the actual storage for the extern variables
str_t programPath = {NULL, 0};
str_t programName = {NULL, 0};
str_t programDirectory = {NULL, 0};
str_t absRunPath = {NULL, 0};

// Helper function to get absolute path
static inline
char* _g_getAbsolutePath(const char* path) {
    if (!path) return NULL;

    #ifdef _WIN32
        char absPath[_G_PATH_MAX];
        LPTSTR filePart;
        if (GetFullPathName(path, _G_PATH_MAX, absPath, &filePart) != 0) {
            char* result = malloc(strlen(absPath) + 1);
            if (result) strcpy(result, absPath);
            return result;
        }
    #else
        char* resolved = realpath(path, NULL);
        return resolved;  // realpath allocates memory
    #endif

    return NULL;
}

// Helper function to get current working directory
static inline
char* _g_getCurrentDirectory(void) {
    char cwd[_G_PATH_MAX];

    #ifdef _WIN32
        if (GetCurrentDirectory(_G_PATH_MAX, cwd) != 0) {
            char* result = malloc(strlen(cwd) + 1);
            if (result) strcpy(result, cwd);
            return result;
        }
    #else
        if (getcwd(cwd, sizeof(cwd)) != NULL) {
            char* result = malloc(strlen(cwd) + 1);
            if (result) strcpy(result, cwd);
            return result;
        }
    #endif

    return NULL;
}

void initGlobals(const int argc, char* argv[]) {
    // Initialize absolute run path first (current directory)
    const char* absPath = _g_getCurrentDirectory();
    if (absPath) {
        absRunPath.data = absPath;
        absRunPath.length = strlen(absPath);
    } else {
        absRunPath.data = ".";
        absRunPath.length = 1;
    }

    // argv[0] always exists - it's the program path
    if (argc > 0 && argv[0]) {
        // Get absolute path of the executable
        const char* resolvedPath = _g_getAbsolutePath(argv[0]);
        if (resolvedPath) {
            programPath.data = resolvedPath;
            programPath.length = strlen(resolvedPath);
        } else {
            // Fallback to the provided path
            char* pathCopy = malloc(strlen(argv[0]) + 1);
            if (pathCopy) {
                strcpy(pathCopy, argv[0]);
                programPath.data = pathCopy;
                programPath.length = strlen(pathCopy);
            }
        }

        // Extract program name (last component of path)
        const char* pathToUse = programPath.data ? programPath.data : argv[0];
        const char* lastSlash = strrchr(pathToUse, '/');
        if (!lastSlash) {
            lastSlash = strrchr(pathToUse, '\\'); // For Windows paths
        }

        if (lastSlash) {
            // Program name is after the last slash
            char* nameCopy = malloc(strlen(lastSlash + 1) + 1);
            if (nameCopy) {
                strcpy(nameCopy, lastSlash + 1);
                programName.data = nameCopy;
                programName.length = strlen(nameCopy);
            }

            // Program directory is up to the last slash
            const size_t dirLen = lastSlash - pathToUse;
            if (dirLen > 0) {
                char* dirCopy = malloc(dirLen + 1);
                if (dirCopy) {
                    strncpy(dirCopy, pathToUse, dirLen);
                    dirCopy[dirLen] = '\0';
                    programDirectory.data = dirCopy;
                    programDirectory.length = dirLen;
                }
            } else {
                // No directory part, use current directory
                programDirectory.data = absRunPath.data;
                programDirectory.length = absRunPath.length;
            }
        } else {
            // No path separators, program is in current directory
            char* nameCopy = malloc(strlen(pathToUse) + 1);
            if (nameCopy) {
                strcpy(nameCopy, pathToUse);
                programName.data = nameCopy;
                programName.length = strlen(nameCopy);
            }

            // Use current directory as program directory
            programDirectory.data = absRunPath.data;
            programDirectory.length = absRunPath.length;
        }
    }
}

void logGlobals() {
    printf("Program path: %.*s\n", (int)programPath.length, programPath.data ? programPath.data : "NULL");
    printf("Program name: %.*s\n", (int)programName.length, programName.data ? programName.data : "NULL");
    printf("Program directory: %.*s\n", (int)programDirectory.length, programDirectory.data ? programDirectory.data : "NULL");
    printf("Absolute run path: %.*s\n", (int)absRunPath.length, absRunPath.data ? absRunPath.data : "NULL");
}

void cleanupGlobals(void) {
    // Free allocated memory
    if (programPath.data && programPath.data != absRunPath.data) {
        free((void*)programPath.data);
        programPath.data = NULL;
    }
    if (programName.data) {
        free((void*)programName.data);
        programName.data = NULL;
    }
    if (programDirectory.data && programDirectory.data != absRunPath.data) {
        free((void*)programDirectory.data);
        programDirectory.data = NULL;
    }
    if (absRunPath.data && absRunPath.data != (void*)1 && strcmp(absRunPath.data, ".") != 0) {
        free((void*)absRunPath.data);
        absRunPath.data = NULL;
    }
}