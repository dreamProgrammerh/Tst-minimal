#pragma once

#if __STDC_VERSION__ >= 202311L
    #include <stddef.h>  // For nullptr_t
    #define final constexpr
#else
    #define nullptr ((void*)0)
    #define final static const
    // Fallback implementations
#endif