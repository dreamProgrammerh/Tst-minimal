#pragma once

#if __STDC_VERSION__ >= 202311L
    #include <stddef.h>  // For nullptr_t
    #define final constexpr
    #define CONST(name, type) constexpr type name
#else
    #define nullptr ((void*)0)
    #define final static const
    #define CONST(name, type) #define name (type)
    // Fallback implementations
#endif