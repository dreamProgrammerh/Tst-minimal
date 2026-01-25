#include <stdio.h>

#define MATH_PREFIX fmath_
#define MATH_DEFINITION 1
#include "ftime.h"
#include "fmath.c"

int main() {
    clockUs();
    fmath_initRandom();

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
// gcc -DMATH_PREFIX=fmath_ -DMATH_DEFINITION=1 -o fastMath.dll -shared -O3 fmath.c

// Linux/macOS
// gcc -DMATH_PREFIX=fmath_ -DMATH_DEFINITION=1 -o fastMath.so -shared -O3 -fPIC fmath.c

// macOS (dynamic library)
// gcc -DMATH_PREFIX=fmath_ -DMATH_DEFINITION=1 -o fastMath.dylib -dynamiclib -O3 -fPIC fmath.c
 