#include <stdio.h>

#define MATH_PREFIX fmath_
#define MATH_DEFINITION 1
#include "fmath.c"
#include "kthindex.c"

int cmp(const void* a, const void* b) {
    return *(i32*)a - *(i32*)b;
}
int cmp2(void* ctx, const i32 i1, const i32 i2) {
    f64* arr = ctx;
    const f64 res = arr[i1] - arr[i2];
    return res > 0 ? 1 : res < 0 ? -1 : 0;
}

int main() {
    fmath_init();

    const i32 arri[] = {2, 1, 3, 5, 9, 8};
    const f64 arrd[] = {.2, .1, .3, .5, .9, .8};
    const u32 sizei = sizeof(arri) / sizeof(arri[0]);
    const u32 sized = sizeof(arrd) / sizeof(arrd[0]);

    printf("med int: %d\n", arri[KthIndexInt((i32*)&arri, sizei, 0)]);
    printf("big 2 double: %g\n", arrd[KthIndexDouble((f64*)&arrd, sized, -2)]);
    printf("big 1 compare gen: %d\n", arri[KthIndexGeneric((void*)&arri, sizei, -1, sizeof(arri[0]), cmp)]);
    printf("small 4 compare ctx: %g\n", arrd[KthIndexContext(sized, 4, (void*)&arrd, cmp2)]);
    
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
// gcc -DMATH_PREFIX=fmath_ -DMATH_DEFINITION=1 -o fmath.dll -shared -O3 fmath.c kthindex.c

// Linux/macOS
// gcc -DMATH_PREFIX=fmath_ -DMATH_DEFINITION=1 -o fmath.so -shared -O3 -fPIC fmath.c kthindex.c

// macOS (dynamic library)
// gcc -DMATH_PREFIX=fmath_ -DMATH_DEFINITION=1 -o fmath.dylib -dynamiclib -O3 -fPIC fmath.c kthindex.c
 