// fmath.c - Implementation

#if MATH_DEFINITION

#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "fmath.h"
#include "ftime.h"

// ==================
//     GLOBALS
// ==================
static u64 _initTime;
u64 _rstate;
u64 _rseed;

// ==================
//     UTILITIES
// ==================

// Constants from Dart's _RandomImplementation
static const u64 _a = 0x5DEECE66D;
static const u64 _c = 0xB;
static const u64 _m = 1ULL << 48;
static const u64 _mask48 = (1ULL << 48) - 1;
static const u64 _maxint = 0x7FFFFFFF; /* 2,147,483,647 */
static const f64 _rrange = 1.0 / (1ULL << 53);

u64 PREFIXED(now)() {
    return nowUs();
}

u64 PREFIXED(uptime)() {
    return uptimeUs();
}

u64 PREFIXED(clock)() {
    return clockUs();
}

void PREFIXED(initRandom)() {
    clockUs(); // init start time
    _initTime = PREFIXED(now)();
    PREFIXED(seed)(0);
}

u64 _nextState() {
    return _rstate = (_a * _rstate + _c) & _mask48;
}

u64 _nextBits(const i32 bits) {
    return _nextState() >> 48 - bits;
}

u64 PREFIXED(genseed)() {
  return nowUs() ^ (_initTime + uptimeUs());
}

void PREFIXED(seed)(const u64 seed) {
    _rseed = seed == 0
        ? PREFIXED(genseed)()
        : seed;

    _rstate = (_rseed ^ _a) & _mask48;

    // Warm up
    _nextState();
}

f64 PREFIXED(random)() {
    // Generate 53 random bits (IEEE f64 has 53 bits of mantissa)
    const u64 high26 = _nextBits(26);
    const u64 low27 = _nextBits(27);

    // Combine into 53-bit integer
    const u64 combined = (high26 << 27) | low27;

    // Convert to f64 in range [0, 1)
    return (f64)combined * _rrange;
}

i32 PREFIXED(randomInt)(const i32 max) {
    assert(0 < max && max <= _maxint);

    // Fast path for powers of two
    if ((max & (max - 1)) == 0) {
      return _nextBits(31) & (max - 1);
    }

    // Rejection sampling for uniform distribution
    u64 bits, val;
    do {
      bits = _nextBits(31);
      val = bits % max;
    } while (bits - val + (max - 1) < 0);

    return val;
}

bool PREFIXED(randomBool)() {
    return _nextBits(1) == 0;
}

u8 PREFIXED(randomByte)() {
    return (u8)(_nextBits(8) & 0xFF);
}

// Generate bytes
void PREFIXED(randomBytes(u8* buffer, const u64 size)) {
    u64 i = 0;
    while (i < size) {
      u64 random = _nextBits(32);
      for (i32 j = 0; j < 4 && i < size; j++) {
        buffer[i++] = random & 0xFF;
        random >>= 8;
      }
    }
}

f64 PREFIXED(abs)(const f64 x) { return x < 0 ? -x : x; }
i32 PREFIXED(sign)(const f64 x) { return (x > 0) - (x < 0); }

f64 PREFIXED(floor)(const f64 x) { return floor(x); }
f64 PREFIXED(ceil)(const f64 x) { return ceil(x); }
f64 PREFIXED(trunc)(const f64 x) { return trunc(x); }
f64 PREFIXED(round)(const f64 x) { return round(x); }

f64 PREFIXED(snap)(const f64 x, const f64 y) { return round(x / y) * y; }
f64 PREFIXED(snapOffset)(const f64 x, const f64 y, const f64 offset) {
    return round((x - offset) / y) * y + offset;
}

f64 PREFIXED(lerp)(const f64 a, const f64 b, const f64 t) {
    return a + t * (b - a);
}

f64 PREFIXED(mod)(const f64 a, const f64 b) {
    if (b == 0.0) return NAN;
    const f64 result = fmod(a, b);
    return result >= 0 ? result : result + b;
}

f64 PREFIXED(remainder)(const f64 a, const f64 b) {
    if (b == 0.0) return NAN;
    return a - round(a / b) * b;
}

f64 PREFIXED(wrap)(const f64 a, const f64 b) {
    return fmod(fmod(a, b) + b, b);
}

f64 PREFIXED(wrapRange)(const f64 value, const f64 min, const f64 max) {
    const f64 range = max - min;
    return fmod(fmod(value - min, range) + range, range) + min;
}

f64 PREFIXED(step)(const f64 edge, const f64 x) {
    return x < edge ? 0.0 : 1.0;
}

u64 PREFIXED(factorial)(const i32 n) {
    if (n < 0) return 0;
    if (n > 20) return U64_MAX;

    static const u64 factorials[] = {
        1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880,
        3628800, 39916800, 479001600ULL, 6227020800ULL, 87178291200ULL,
        1307674368000ULL, 20922789888000ULL, 355687428096000ULL,
        6402373705728000ULL, 121645100408832000ULL, 2432902008176640000ULL
    };

    return factorials[n];
}

u64 PREFIXED(binomial)(const i32 n, const i32 k) {
    if (k < 0 || k > n) return 0;
    if (k == 0 || k == n) return 1;
    i32 K = k;

    if (K > n - K) K = n - K;

    u64 result = 1;
    for (i32 i = 1; i <= K; i++) {
        result = result * (n - K + i) / i;
    }
    return result;
}

f64 PREFIXED(toRadians)(const f64 degrees) { return degrees * DEG_TO_RAD; }
f64 PREFIXED(toDegrees)(const f64 radians) { return radians * RAD_TO_DEG; }

f64 PREFIXED(length)(const f64 x, const f64 y) { return sqrt(x * x + y * y); }
f64 PREFIXED(lengthSq)(const f64 x, const f64 y) { return x * x + y * y; }
f64 PREFIXED(dot)(const f64 x1, const f64 y1, const f64 x2, const f64 y2) { return x1 * x2 + y1 * y2; }

f64 PREFIXED(distance)(const f64 x1, const f64 y1, const f64 x2, const f64 y2) {
    const f64 dx = x2 - x1;
    const f64 dy = y2 - y1;
    return sqrt(dx * dx + dy * dy);
}

f64 PREFIXED(distanceSq)(const f64 x1, const f64 y1, const f64 x2, const f64 y2) {
    const f64 dx = x2 - x1;
    const f64 dy = y2 - y1;
    return dx * dx + dy * dy;
}

f64 PREFIXED(intPow)(const f64 base, const i32 exponent) {
    if (exponent == 0) return 1.0;
    if (exponent == 1) return base;
    if (exponent == 2) return base * base;
    if (exponent == 3) return base * base * base;

    f64 result = 1.0;
    f64 current = base;
    i32 n = exponent > 0 ? exponent : -exponent;

    while (n > 0) {
        if (n & 1) result *= current;
        current *= current;
        n >>= 1;
    }

    return exponent > 0 ? result : 1.0 / result;
}

f64 PREFIXED(remap)(const f64 value, const f64 inMin, const f64 inMax, const f64 outMin, const f64 outMax) {
    const f64 t = (value - inMin) / (inMax - inMin);
    return outMin + t * (outMax - outMin);
}

f64 PREFIXED(unit)(const f64 value, const f64 min, const f64 max) {
    return (value - min) / (max - min);
}

f64 PREFIXED(expand)(const f64 value, const f64 min, const f64 max) {
    return min + value * (max - min);
}

f64 PREFIXED(smoothstep)(const f64 t) { return t * t * (3.0 - 2.0 * t); }
f64 PREFIXED(smootherstep)(const f64 t) { return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); }
f64 PREFIXED(easeIn)(const f64 t) { return t * t; }
f64 PREFIXED(easeOut)(const f64 t) { return 1.0 - (1.0 - t) * (1.0 - t); }
f64 PREFIXED(easeInOut)(const f64 t) {
    return t < 0.5 ? 4.0 * t * t * t : 1.0 - pow(-2.0 * t + 2.0, 3.0) * 0.5;
}

f64 PREFIXED(cubicBezier)(const f64 p0, const f64 p1, const f64 p2, const f64 p3, const f64 t) {
    const f64 u = 1.0 - t;
    const f64 u2 = u * u;
    const f64 t2 = t * t;
    return u2 * u * p0 + 3.0 * u2 * t * p1 + 3.0 * u * t2 * p2 + t2 * t * p3;
}

f64 PREFIXED(noise)(const f64 x, const f64 y, const u64 seed) {
    const u64 t = seed == 0 ? PREFIXED(genseed)() : seed;
    const i32 x0 = (int)floor(x);
    const i32 y0 = (int)floor(y);
    const i32 x1 = x0 + 1;
    const i32 y1 = y0 + 1;

    const f64 sx = x - x0;
    const f64 sy = y - y0;

    // Simple hash function
    u32 hash1 = (x0 * 1619 + y0 * 31337 + t) * 0xcc9e2d51;
    hash1 = (hash1 << 15) | (hash1 >> 17);
    hash1 *= 0x1b873593;

    u32 hash2 = (x1 * 1619 + y0 * 31337 + t) * 0xcc9e2d51;
    hash2 = (hash2 << 15) | (hash2 >> 17);
    hash2 *= 0x1b873593;

    f64 n0 = (hash1 / 4294967295.0) * 2.0 - 1.0;
    f64 n1 = (hash2 / 4294967295.0) * 2.0 - 1.0;

    const f64 ix0 = PREFIXED(lerp(n0, n1, PREFIXED(smootherstep(sx))));

    u32 hash3 = (x0 * 1619 + y1 * 31337 + t) * 0xcc9e2d51;
    hash3 = (hash3 << 15) | (hash3 >> 17);
    hash3 *= 0x1b873593;

    u32 hash4 = (x1 * 1619 + y1 * 31337 + t) * 0xcc9e2d51;
    hash4 = (hash4 << 15) | (hash4 >> 17);
    hash4 *= 0x1b873593;

    n0 = (hash3 / 4294967295.0) * 2.0 - 1.0;
    n1 = (hash4 / 4294967295.0) * 2.0 - 1.0;

    const f64 ix1 = PREFIXED(lerp(n0, n1, PREFIXED(smootherstep(sx))));

    return PREFIXED(lerp(ix0, ix1, PREFIXED(smootherstep(sy))));
}

// ==================
//   ROUGH FUNCTIONS
// ==================

static inline f64 reduceAngle(const f64 angle) {
    f64 x = fmod(angle, MATH_TAU);
    if (x > MATH_PI) x -= MATH_TAU;
    if (x < -MATH_PI) x += MATH_TAU;
    return x;
}

f64 PREFIXED(rexp)(const f64 x) {
    if (x > 709.78) return INFINITY;
    if (x < -745.13) return 0.0;
    if (x == 0.0) return 1.0;

    const f64 p0 = 1.0;
    const f64 p1 = 0.4999999999999999;
    const f64 p2 = 0.16666666666666602;
    const f64 p3 = 0.04166666666643267;
    const f64 p4 = 0.00833333333323918;

    const f64 q0 = 1.0;
    const f64 q1 = -0.4999999999999999;
    const f64 q2 = 0.16666666666666602;
    const f64 q3 = -0.04166666666643267;
    const f64 q4 = 0.00833333333323918;

    const f64 x2 = x * x;
    const f64 x3 = x2 * x;
    const f64 x4 = x2 * x2;

    const f64 numerator = p0 + p1 * x + p2 * x2 + p3 * x3 + p4 * x4;
    const f64 denominator = q0 + q1 * x + q2 * x2 + q3 * x3 + q4 * x4;

    return numerator / denominator;
}

f64 PREFIXED(rlog)(const f64 x) {
    if (x <= 0.0) return NAN;
    f64 X = x;

    i32 exponent = 0;
    while (X >= 2.0) { X *= 0.5; exponent++; }
    while (X < 1.0) { X *= 2.0; exponent--; }

    const f64 y = X - 1.0;
    const f64 c1 = 0.9999964239;
    const f64 c2 = -0.4998741238;
    const f64 c3 = 0.3317990258;
    const f64 c4 = -0.2407338084;
    const f64 c5 = 0.1676540711;
    const f64 c6 = -0.0953293897;
    const f64 c7 = 0.0360884937;
    const f64 c8 = -0.0064535442;

    const f64 poly = y * (c1 + y * (c2 + y * (c3 + y * (c4 + y *
               (c5 + y * (c6 + y * (c7 + y * c8)))))));

    return exponent * MATH_LN2 + poly;
}

f64 PREFIXED(rlog10)(const f64 x) {
    return PREFIXED(rlog(x)) * 0.4342944819032518;
}

f64 PREFIXED(risqrt)(const f64 x) {
    const f64 xhalf = 0.5 * x;
    i64 i;
    memcpy(&i, &x, sizeof(f64));
    i = 0x5FE6EB50C7B537A9 - (i >> 1);
    f64 y;
    memcpy(&y, &i, sizeof(f64));
    y = y * (1.5 - (xhalf * y * y));
    return y;
}

f64 PREFIXED(rsqrt)(const f64 x) {
    if (x < 0.0) return NAN;
    if (x == 0.0) return 0.0;
    return x * PREFIXED(risqrt(x));
}

f64 PREFIXED(rsin)(const f64 x) {
    const f64 X = reduceAngle(x);
    return (16.0 * X * (MATH_PI - X)) / (5.0 * MATH_TAU - 4.0 * X * (MATH_PI - X));
}

f64 PREFIXED(rcos)(const f64 x) {
    return PREFIXED(rsin(MATH_HALF_PI - x));
}

f64 PREFIXED(rtan)(const f64 x) {
    const f64 cosx = PREFIXED(rcos(x));
    const f64 sinx = PREFIXED(rsin(x));
    return fabs(cosx) < 1e-15 ? (sinx > 0 ? INFINITY : -INFINITY) : sinx / cosx;
}

f64 PREFIXED(rasin)(const f64 x) {
    if (x < -1.0 || x > 1.0) return NAN;
    return PREFIXED(ratan2(x, PREFIXED(rsqrt(1.0 - x * x))));
}

f64 PREFIXED(racos)(const f64 x) {
    if (x < -1.0 || x > 1.0) return NAN;
    return MATH_HALF_PI - PREFIXED(rasin(x));
}

f64 PREFIXED(ratan)(const f64 x) {
    const f64 a1 = 0.99997726;
    const f64 a3 = -0.33262347;
    const f64 a5 = 0.19354346;
    const f64 a7 = -0.11643287;
    const f64 a9 = 0.05265332;
    const f64 a11 = -0.01172120;

    const f64 x2 = x * x;
    return x * (a1 + x2 * (a3 + x2 * (a5 + x2 * (a7 + x2 * (a9 + x2 * a11)))));
}

f64 PREFIXED(ratan2)(const f64 y, const f64 x) {
    if (x == 0.0) {
        if (y == 0.0) return 0.0;
        return y > 0 ? MATH_HALF_PI : -MATH_HALF_PI;
    }

    const f64 ratio = y / x;
    f64 angle = PREFIXED(ratan(ratio));

    if (x < 0.0) {
        angle = (y >= 0.0) ? angle + MATH_PI : angle - MATH_PI;
    }

    return angle;
}

f64 PREFIXED(rpow)(const f64 x, const f64 exponent) {
    if (exponent == 0.0) return 1.0;
    if (x == 0.0) return 0.0;
    if (x == 1.0) return 1.0;

    // Use fast exp(log) approximation
    return PREFIXED(rexp(exponent * PREFIXED(rlog(x))));
}

f64 PREFIXED(rhypot)(const f64 x, const f64 y) {
    // Fast hypot using max * sqrt(1 + (min/max)²)
    const f64 ax = fabs(x);
    const f64 ay = fabs(y);

    if (ax == 0.0) return ay;
    if (ay == 0.0) return ax;

    if (ax > ay) {
        const f64 r = ay / ax;
        return ax * PREFIXED(rsqrt(1.0 + r * r));
    } else {
        const f64 r = ax / ay;
        return ay * PREFIXED(rsqrt(1.0 + r * r));
    }
}

f64 PREFIXED(sin)(const f64 x) { return sin(x); }
f64 PREFIXED(cos)(const f64 x) { return cos(x); }
f64 PREFIXED(tan)(const f64 x) { return tan(x); }
f64 PREFIXED(asin)(const f64 x) { return asin(x); }
f64 PREFIXED(acos)(const f64 x) { return acos(x); }
f64 PREFIXED(atan)(const f64 x) { return atan(x); }
f64 PREFIXED(atan2)(const f64 y, const f64 x) { return atan2(y, x); }
f64 PREFIXED(exp)(const f64 x) { return exp(x); }
f64 PREFIXED(log)(const f64 x) { return log(x); }
f64 PREFIXED(log10)(const f64 x) { return log10(x); }
f64 PREFIXED(sqrt)(const f64 x) { return sqrt(x); }
f64 PREFIXED(pow)(const f64 x, const f64 y) { return pow(x, y); }
f64 PREFIXED(hypot)(const f64 x, const f64 y) { return hypot(x, y); }

#endif // MATH_DEFINITION
