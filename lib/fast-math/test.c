#include <stdio.h>
#include <time.h>

#define MATH_PREFIX m_
#define MATH_DEFINITION 1
#include "ftime.h"
#include "fmath.c"

int main() {
    clockUs();
    m_initRandom();

    printf("now: %lld\n", m_now());
    printf("uptime: %lld\n", m_uptime());
    printf("clock: %lld\n", m_clock());
    printf("clock: %lld\n", clock());
    
    printf("float: %g\n", m_random());
    printf("float: %g\n", m_random());
    printf("int 45: %d\n", m_randomInt(45));
    printf("int 45: %d\n", m_randomInt(45));
    printf("int 45: %d\n", m_randomInt(45));
    printf("bool: %s\n", m_randomBool() ? "true" : "false");
    printf("bool: %s\n", m_randomBool() ? "true" : "false");
    printf("noise x56 y98: %g\n", m_noise(56, 98, 0));
}

// Windows
// gcc -o fastMath.dll -shared -O3 fmath.c

// Linux/macOS
// gcc -o fastMath.so -shared -O3 -fPIC fmath.c

// macOS (dynamic library)
// gcc -o fastMath.dylib -dynamiclib -O3 -fPIC fmath.c  