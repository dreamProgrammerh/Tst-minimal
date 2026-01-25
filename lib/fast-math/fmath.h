// fmath.h - Fast approximate math library with configurable prefix
#ifndef FMATH_H
#define FMATH_H

#include "types.h"

// Default prefix if not defined
#ifndef MATH_PREFIX
#define MATH_PREFIX math_
#endif

// Helper macro for concatenating prefix with names
#define CONCAT2(a, b) a ## b
#define CONCAT(a, b) CONCAT2(a, b)

// Used for prefix function declarations
#define PREFIXED(name) CONCAT(MATH_PREFIX, name)

#define MATH_DEFINITION 1
#ifdef __cplusplus
extern "C" {
#endif

// ==================
//     CONSTANTS
// ==================
#define MATH_E       2.718281828459045
#define MATH_PI      3.14159265358979323846
#define MATH_HALF_PI 1.5707963267948966
#define MATH_TAU     6.283185307179586
#define MATH_LN2     0.6931471805599453
#define MATH_LN10    2.302585092994046
#define MATH_SQRT2   1.4142135623730951
#define MATH_INV_PI  0.3183098861837907

#define DEG_TO_RAD   0.017453292519943295
#define RAD_TO_DEG   57.29577951308232

// ==================
//     GLOBALS
// ==================
extern u64 _rstate;
extern u64 _rseed;

// ==================
//     UTILITIES
// ==================

void PREFIXED(init)();

u64 PREFIXED(now)();
u64 PREFIXED(uptime)();
u64 PREFIXED(clock)();

u64 PREFIXED(genseed)();
void PREFIXED(seed)(u64 seed);
f64 PREFIXED(random)();
i32 PREFIXED(randomInt)(i32 max);
bool PREFIXED(randomBool)();
u8 PREFIXED(randomByte)();
void PREFIXED(randomBytes(u8* buffer, const u64 size));

// Min/Max/Med/Clamp - these are macros so they don't get prefixed
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#define MED(a, b, c) ((a) > (b) ? ((b) > (c) ? (b) : ((a) > (c) ? (c) : (a))) : ((a) > (c) ? (a) : ((b) > (c) ? (c) : (b))))
#define CLAMP(v, lo, hi) ((v) <= (lo) ? (lo) : ((v) >= (hi) ? (hi) : (v)))

// Function versions with prefix
f64 PREFIXED(min)(f64 a, f64 b);
f64 PREFIXED(max)(f64 a, f64 b);
f64 PREFIXED(med)(f64 a, f64 b, f64 c);
f64 PREFIXED(clamp)(f64 value, f64 min, f64 max);

f64 PREFIXED(abs)(f64 x);
i32 PREFIXED(sign)(f64 x);

// Rounding
f64 PREFIXED(floor)(f64 x);
f64 PREFIXED(ceil)(f64 x);
f64 PREFIXED(trunc)(f64 x);
f64 PREFIXED(round)(f64 x);
f64 PREFIXED(snap)(f64 x, f64 y);
f64 PREFIXED(snapOffset)(f64 x, f64 y, f64 offset);

// LERP & Mod
f64 PREFIXED(lerp)(f64 a, f64 b, f64 t);
f64 PREFIXED(mod)(f64 a, f64 b);
f64 PREFIXED(remainder)(f64 a, f64 b);
f64 PREFIXED(wrap)(f64 a, f64 b);
f64 PREFIXED(wrapRange)(f64 value, f64 min, f64 max);
f64 PREFIXED(step)(f64 edge, f64 x);

// Factorial & Binomial
u64 PREFIXED(factorial)(i32 n);
u64 PREFIXED(binomial)(i32 n, i32 k);

// Conversions
f64 PREFIXED(toRadians)(f64 degrees);
f64 PREFIXED(toDegrees)(f64 radians);

// 2D Geometry
f64 PREFIXED(length)(f64 x, f64 y);
f64 PREFIXED(lengthSq)(f64 x, f64 y);
f64 PREFIXED(dot)(f64 x1, f64 y1, f64 x2, f64 y2);
f64 PREFIXED(distance)(f64 x1, f64 y1, f64 x2, f64 y2);
f64 PREFIXED(distanceSq)(f64 x1, f64 y1, f64 x2, f64 y2);

// Integer power
f64 PREFIXED(intPow)(f64 base, i32 exponent);

// Remapping
f64 PREFIXED(remap)(f64 value, f64 inMin, f64 inMax, f64 outMin, f64 outMax);
f64 PREFIXED(unit)(f64 value, f64 min, f64 max);
f64 PREFIXED(expand)(f64 value, f64 min, f64 max);

// Easing functions
f64 PREFIXED(smoothstep)(f64 t);
f64 PREFIXED(smootherstep)(f64 t);
f64 PREFIXED(easeIn)(f64 t);
f64 PREFIXED(easeOut)(f64 t);
f64 PREFIXED(easeInOut)(f64 t);

// Bezier
f64 PREFIXED(cubicBezier)(f64 p0, f64 p1, f64 p2, f64 p3, f64 t);

// Noise
f64 PREFIXED(noise)(f64 x, f64 y, u64 seed);

// ==================
//   ROUGH FUNCTIONS (R PREFIX)
// ==================
f64 PREFIXED(rexp)(f64 x);
f64 PREFIXED(rlog)(f64 x);
f64 PREFIXED(rlog10)(f64 x);
f64 PREFIXED(risqrt)(f64 x);
f64 PREFIXED(rsqrt)(f64 x);
f64 PREFIXED(rsin)(f64 x);
f64 PREFIXED(rcos)(f64 x);
f64 PREFIXED(rtan)(f64 x);
f64 PREFIXED(rasin)(f64 x);
f64 PREFIXED(racos)(f64 x);
f64 PREFIXED(ratan)(f64 x);
f64 PREFIXED(ratan2)(f64 y, f64 x);
f64 PREFIXED(rpow)(f64 x, f64 exponent);
f64 PREFIXED(rhypot)(f64 x, f64 y);

// ==================
//   ACCURATE VERSIONS
// ==================
f64 PREFIXED(sin)(f64 x);
f64 PREFIXED(cos)(f64 x);
f64 PREFIXED(tan)(f64 x);
f64 PREFIXED(asin)(f64 x);
f64 PREFIXED(acos)(f64 x);
f64 PREFIXED(atan)(f64 x);
f64 PREFIXED(atan2)(f64 y, f64 x);
f64 PREFIXED(exp)(f64 x);
f64 PREFIXED(log)(f64 x);
f64 PREFIXED(log10)(f64 x);
f64 PREFIXED(sqrt)(f64 x);
f64 PREFIXED(pow)(f64 x, f64 y);
f64 PREFIXED(hypot)(f64 x, f64 y);

#ifdef __cplusplus
}
#endif

#endif // FMATH_H