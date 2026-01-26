#include <stdio.h>

#define MATH_PREFIX fmath_
#define MATH_DEFINITION 1
#include "ftime.h"

#include "fmath.c"
#include "kthindex.c"

int main() {
    fmath_init();

    const i32 arri[] = {2, 1, 3, 5, 9, 8};
    const f64 arrd[] = {.2, .1, .3, .5, .9, .8};
    const u32 sizei = sizeof(arri) / sizeof(arri[0]);
    const u32 sized = sizeof(arrd) / sizeof(arrd[0]);

    printf("med int: %d\n", arri[KthIndexInt((i32*)&arri, sizei, KTH_MEDIAN)]);
    printf("med double: %g\n", arrd[KthIndexDouble((f64*)&arrd, sized, -2)]);
    printf("init: %lld\n", _initTime);
    printf("genseed: %lld\n", fmath_genseed());
    printf("now: %lld\n", fmath_now());
    printf("uptime: %lld\n", fmath_uptime());
    printf("clock: %lld\n", fmath_clock());
    
    printf("float: %g\n", fmath_random());
    printf("float: %g\n", fmath_random());
    printf("int 45: %d\n", fmath_randomInt(45));
    printf("int 45: %d\n", fmath_randomInt(45));
    printf("int 45: %d\n", fmath_randomInt(45));
    printf("bool: %s\n", fmath_randomBool() ? "true" : "false");
    printf("bool: %s\n", fmath_randomBool() ? "true" : "false");
    printf("noise x56 y98: %g\n", fmath_noise(56, 98, 0));
}

// Windows
// gcc -DMATH_PREFIX=fmath_ -DMATH_DEFINITION=1 -o fastMath.dll -shared -O3 fmath.c kthindex.c

// Linux/macOS
// gcc -DMATH_PREFIX=fmath_ -DMATH_DEFINITION=1 -o fastMath.so -shared -O3 -fPIC fmath.c kthindex.c

// macOS (dynamic library)
// gcc -DMATH_PREFIX=fmath_ -DMATH_DEFINITION=1 -o fastMath.dylib -dynamiclib -O3 -fPIC fmath.c kthindex.c
 