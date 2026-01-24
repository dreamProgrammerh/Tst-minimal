#ifndef __TYPES_H__
#define __TYPES_H__

typedef signed char           i8;
typedef signed short          i16;
typedef signed int            i32;
typedef signed long long      i64;

typedef unsigned char         u8;
typedef unsigned short        u16;
typedef unsigned int          u32;
typedef unsigned long long    u64;

typedef float                 f32;
typedef double                f64;

#define I8_MIN (-128)
#define I16_MIN (-32768)
#define I32_MIN (-2147483647 - 1)
#define I64_MIN  (-9223372036854775807LL - 1)

#define I8_MAX 127
#define I16_MAX 32767
#define I32_MAX 2147483647
#define I64_MAX 9223372036854775807LL

#define U8_MAX 255
#define U16_MAX 65535
#define U32_MAX 0xffffffffU  /* 4294967295U */
#define U64_MAX 0xffffffffffffffffULL /* 18446744073709551615ULL */
typedef unsigned char bool;

#define true 1
#define false 0

#endif // __TYPES_H__