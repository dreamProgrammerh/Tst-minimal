#pragma once

#include <stdint.h>
#include <stdbool.h>

#include "platform.h"

typedef uint8_t byte;

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef int8_t i8;
typedef int16_t i16;
typedef int32_t i32;
typedef int64_t i64;

typedef float f32;
typedef double f64;

#if ARCH_is64BIT
    typedef u64 usize;
    typedef i64 isize;
    typedef f64 fsize;
#elif ARCH_is32BIT
    typedef u32 usize;
    typedef i32 isize;
    typedef f32 fsize;
#endif