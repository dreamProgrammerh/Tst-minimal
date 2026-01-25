/// Fast Math Library - High-performance mathematical functions for Dart
/// ====================================================================
/// 
/// Provides both accurate IEEE 754-compliant functions and fast approximate
/// versions optimized for real-time applications.
/// 
/// Author: dreamProgrammer
/// Version: 1.0.0
/// 
/// Quick Start:
/// ------------
/// 1. Call load_fmathLib() once at application startup
/// 2. Use standard functions (sin, cos) for accuracy
/// 3. Use rough functions (rsin, rcos) for speed
/// 4. Call seed() and random() for random numbers
/// 

import 'dart:ffi' as c;
import 'dart:io';
import 'dart:typed_data';

const _p = 'fmath_'; // prefix
final String? _libraryPath =
        Platform.isWindows ? "lib/fastMath.dll"
      : Platform.isMacOS ? "lib/fastMath.dylib"
      : Platform.isLinux ? "lib/fastMath.so"
      : null;
      
final _malloc = c.DynamicLibrary.process().lookupFunction<
  c.Pointer<c.Void> Function(c.IntPtr size),
  c.Pointer<c.Void> Function(int size)
>('malloc');

final _free = c.DynamicLibrary.process().lookupFunction<
  c.Void Function(c.Pointer<c.Void> ptr),
  void Function(c.Pointer<c.Void> ptr)
>('free');

/// The operating system is not supported.
@pragma("vm:entry-point")
class UnsupportedOSError extends Error {
  final String os;
  @pragma("vm:entry-point")
  UnsupportedOSError(this.os);
  String toString() => "Unsupported Operating System: $os";
}

/// Promised library was missing.
///
/// This [Error] is thrown when a library expected to exist
/// at specific location yet not found.
@pragma("vm:entry-point")
class MissingLibraryError extends Error {
  final String name;
  final String? path;
  @pragma("vm:entry-point")
  MissingLibraryError(this.name, this.path);
  String toString() => "Missing Library '$name'${path == null ? '' : ' at "$path"'}";
}

/// ====================================================
/// LIBRARY INITIALIZATION
/// ====================================================

late final c.DynamicLibrary _lib;

/// Loads and initializes the native Fast Math library.
/// 
/// This function must be called once before using any math functions 
/// that depend on native implementations (particularly time functions 
/// and advanced mathematical operations).
/// 
/// ## Platform Support
/// - **Windows**: Requires `fastMath.dll`
/// - **macOS**: Requires `fastMath.dylib`
/// - **Linux**: Requires `fastMath.so`
/// - **iOS/Android**: Not supported yet
/// 
/// ## Functionality Loaded
/// After calling this function, the following become available:
/// 1. High-performance native implementations of mathematical functions
/// 2. Precise time measurement functions (`now`, `uptime`, `clock`)
/// 3. System-dependent random number generation
/// 4. Fast approximate (r-prefix) functions with hardware acceleration
/// 
/// ## Usage Example
/// ```dart
/// void main() {
///   // Initialize the math library
///   load_fmathLib();
///   
///   // Now all math functions are available
///   final startTime = now();  // microseconds since epoch
///   final result = rsin(1.0); // fast sine approximation
///   final endTime = now();
///   
///   print('Computation took ${endTime - startTime} us');
/// }
/// ```
/// 
/// ## Error Handling
/// - Throws `UnsupportedOSError` if the current OS is not supported
/// - Throws `MissingLibraryError` if the native library cannot be found
/// - Throws `SymbolLookupError` if function bindings fail
/// 
void load_fmathLib() {
  if (_libraryPath == null)
    throw UnsupportedOSError(Platform.operatingSystem.toString());
  
  else if (! File(_libraryPath!).existsSync())
    throw MissingLibraryError("fastMath", _libraryPath);
    
  _lib = c.DynamicLibrary.open(_libraryPath!);
  
  _loadFunctions();
  _init();
  _loadVariables();
}

/// Mathematical constants and utility functions library.
/// Provides both accurate (standard library) and fast approximate (r-prefix) functions.

// ====================================================
// MATHEMATICAL CONSTANTS
// ====================================================

/// Euler's number (e ≈ 2.718281828459045)
/// Base of natural logarithms, fundamental to exponential growth and calculus.
const double e = 2.718281828459045;

/// Pi (π ≈ 3.1415926535897932)
/// Ratio of a circle's circumference to its diameter.
const double pi = 3.1415926535897932;

/// Half pi (π/2 ≈ 1.5707963267948966)
/// Quarter turn, right angle in radians.
const double hpi = 1.5707963267948966;

/// Tau (τ = 2π ≈ 6.283185307179586)
/// Full circle constant, one turn in radians.
const double tau = 6.283185307179586;

/// Natural log of 2 (ln(2) ≈ 0.6931471805599453)
/// Used in binary logarithms and exponential scaling.
const double ln2 = 0.6931471805599453;

/// Natural log of 10 (ln(10) ≈ 2.302585092994046)
/// Used in common logarithms and scientific notation.
const double ln10 = 2.302585092994046;

/// Square root of 2 (√2 ≈ 1.4142135623730951)
/// Diagonal of a unit square, silver ratio.
const double sqrt2 = 1.4142135623730951;

/// Degrees to radians conversion factor (π/180 ≈ 0.017453292519943295)
/// Multiply degrees by this to get radians.
const double degToRad = pi / 180.0;

/// Radians to degrees conversion factor (180/π ≈ 57.29577951308232)
/// Multiply radians by this to get degrees.
const double radToDeg = 180.0 / pi;

/// Inverse of pi (1/π ≈ 0.3183098861837907)
/// Useful in probability and signal processing.
const double invPi = 1.0 / pi;

// ====================================================
// VARIABLES
// ====================================================

/// The timestamp when the math library was initialized.
/// 
/// This is set when `load_fmathLib()` is called and represents
/// the system uptime in microseconds at initialization.
/// 
/// Useful for:
/// - Measuring time elapsed since library load
/// - Creating time-based IDs that are unique to this program instance
/// - Debugging timing-related issues
/// 
/// Example:
/// ```dart
/// final timeSinceInit = uptime() - initTime;
/// print('Library loaded $timeSinceInit us ago');
/// ```
late final int initTime;

/// The most recent seed value used to initialize the RNG.
/// 
/// This tracks the last seed passed to the `seed()` function,
/// or the auto-generated seed if `seed(0)` was called.
/// 
/// Useful for:
/// - Debugging random number issues
/// - Saving and restoring RNG state in games
/// - Verifying that seeding worked correctly
/// 
/// Example:
/// ```dart
/// seed(42);
/// print('Current RNG seeded with: $lastSeed');  // Prints: 42
/// ```
late final int lastSeed;

/// Current state of the random number generator.
/// 
/// This is the internal state used by the PCG or similar RNG algorithm.
/// Advanced users can read this for debugging or save/restore RNG state.
/// 
/// ! **Warning**: Modifying this directly may break random number sequences.
/// Use `seed()` function to properly reset the RNG state.
/// 
/// Type: 64-bit unsigned integer (platform-dependent)
/// Visibility: Package-private
// ignore: unused_element
late final int _randomState;

// ====================================================
// TIME FUNCTIONS
// ====================================================

/// Initialization function - must be called before using time and random functions
late final void Function() _init;

/// Current timestamp in microseconds since epoch
/// Returns: microseconds since Unix epoch (Jan 1, 1970)
late final int Function() now;

/// System uptime in microseconds
/// Returns: microseconds since system boot
late final int Function() uptime;

/// High-resolution monotonic clock for performance measurement
/// Returns: microseconds from an arbitrary starting point
late final int Function() clock;

/// Generates a random seed by combining multiple system entropy sources
/// 
/// Uses current time, system uptime, process ID, and memory layout
/// to create a unique seed suitable for random number generation.
/// 
/// Returns: A 32-bit integer seed (0 to 4,294,967,295)
/// 
/// Note: Passing seed=0 to seed() or noise() functions will
/// automatically call this function internally.
late final int Function() genseed;

// ====================================================
// RANDOM NUMBER GENERATION
// ====================================================

/// Seeds the random number generator with a specific value
/// [seed]: Integer seed value (use genseed() for random seed)
/// Note: passing zero will generate random seed using genseed()
late final void Function(int seed) seed;

/// Generates a random double in range [0.0, 1.0)
/// Returns: Random value between 0 (inclusive) and 1 (exclusive)
late final double Function() random;

/// Generates a random integer in range [0, max)
/// [max]: Exclusive upper bound (must be > 0)
/// Returns: Random integer where 0 ≤ result < max
late final int Function(int max) randomInt;

/// Generates a random boolean value
/// Returns: true or false with equal probability
late final bool Function() randomBool;

/// Generates a random byte value
/// Returns: Random integer where 0 ≤ result ≤ 255
late final int Function() randomByte;

/// Generates a list of random bytes
/// [size]: Number of bytes to generate
/// Returns: Uint8List of random bytes
late final Uint8List Function(int size) randomBytes;

// ====================================================
// MIN/MAX/CLAMP FUNCTIONS
// ====================================================

/// Returns the smaller of two numbers
/// [a], [b]: Values to compare
/// Returns: min(a, b)
late final double Function(double a, double b) min;

/// Returns the larger of two numbers
/// [a], [b]: Values to compare
/// Returns: max(a, b)
late final double Function(double a, double b) max;

/// Returns the median of three numbers
/// [a], [b], [c]: Values to compare
/// Returns: Middle value when sorted
late final double Function(double a, double b, double c) med;

/// Clamps a value between minimum and maximum bounds
/// [value]: Value to clamp
/// [min]: Minimum allowed value (inclusive)
/// [max]: Maximum allowed value (inclusive)
/// Returns: value clamped to range [min, max]
late final double Function(double value, double min, double max) clamp;

// ====================================================
// BASIC MATH OPERATIONS
// ====================================================

/// Absolute value (magnitude without sign)
/// [x]: Input value
/// Returns: |x|
late final double Function(double x) abs;

/// Sign function (returns -1, 0, or 1)
/// [x]: Input value
/// Returns: -1 if x < 0, 0 if x == 0, 1 if x > 0
late final int Function(double x) sign;

// ====================================================
// ROUNDING FUNCTIONS
// ====================================================

/// Floor - rounds down to nearest integer
/// [x]: Input value
/// Returns: Greatest integer ≤ x
late final double Function(double x) floor;

/// Ceiling - rounds up to nearest integer
/// [x]: Input value
/// Returns: Smallest integer ≥ x
late final double Function(double x) ceil;

/// Truncate - removes fractional part (rounds toward zero)
/// [x]: Input value
/// Returns: Integer part of x
late final double Function(double x) trunc;

/// Round to nearest integer
/// [x]: Input value
/// Returns: x rounded to nearest integer (.5 rounds away from zero)
late final double Function(double x) round;

/// Snaps value to nearest multiple
/// [x]: Value to snap
/// [y]: Snap interval
/// Returns: x rounded to nearest multiple of y
/// Example: snap(17, 5) → 15, snap(18, 5) → 20
late final double Function(double x, double y) snap;

/// Snaps value to nearest multiple with offset
/// [x]: Value to snap
/// [y]: Snap interval
/// [offset]: Offset from zero
/// Returns: x rounded to nearest (multiple of y + offset)
/// Example: snapOffset(17, 5, 2) → 17 (15+2), snapOffset(16, 5, 2) → 12 (10+2)
late final double Function(double x, double y, double offset) snapOffset;

// ====================================================
// INTERPOLATION & MODULO FUNCTIONS
// ====================================================

/// Linear interpolation between two values
/// [a]: Start value (when t = 0)
/// [b]: End value (when t = 1)
/// [t]: Interpolation factor [0, 1]
/// Returns: a + t × (b - a)
late final double Function(double a, double b, double t) lerp;

/// Floating-point modulo with positive result
/// [a]: Dividend
/// [b]: Divisor (must not be zero)
/// Returns: a mod b ∈ [0, b)
/// Example: mod(7, 3) → 1, mod(-7, 3) → 2
late final double Function(double a, double b) mod;

/// Remainder of division (centered around zero)
/// [a]: Dividend
/// [b]: Divisor (must not be zero)
/// Returns: a - round(a/b) × b ∈ [-b/2, b/2]
/// Example: remainder(7, 3) → 1, remainder(-7, 3) → -1
late final double Function(double a, double b) remainder;

/// Wraps value to range [0, b)
/// [a]: Value to wrap
/// [b]: Upper bound (exclusive)
/// Returns: a wrapped cyclically to [0, b)
/// Example: wrap(370, 360) → 10 (wraps angles)
late final double Function(double a, double b) wrap;

/// Wraps value to arbitrary range [min, max)
/// [value]: Value to wrap
/// [min]: Lower bound (inclusive)
/// [max]: Upper bound (exclusive)
/// Returns: value wrapped cyclically to [min, max)
late final double Function(double value, double min, double max) wrapRange;

/// Heaviside step function (returns 0 or 1)
/// [edge]: Threshold value
/// [x]: Input value
/// Returns: 0.0 if x < edge, 1.0 if x ≥ edge
late final double Function(double edge, double x) step;

// ====================================================
// COMBINATORICS
// ====================================================

/// Factorial function (n!)
/// [n]: Non-negative integer (0 ≤ n ≤ 20)
/// Returns: n! = n × (n-1) × ... × 1
/// Case:  0 if n < 0
/// Case: -1 if n > 20  
late final int Function(int n) factorial;

/// Binomial coefficient "n choose k"
/// [n]: Total number of items
/// [k]: Number of items to choose
/// Returns: C(n, k) = n! / (k! × (n-k)!)
late final int Function(int n, int k) binomial;

// ====================================================
// ANGLE CONVERSIONS
// ====================================================

/// Converts degrees to radians
/// [degrees]: Angle in degrees
/// Returns: Angle in radians
/// Formula: radians = degrees × π/180
late final double Function(double degrees) toRadians;

/// Converts radians to degrees
/// [radians]: Angle in radians
/// Returns: Angle in degrees
/// Formula: degrees = radians × 180/π
late final double Function(double radians) toDegrees;

// ====================================================
// 2D GEOMETRY FUNCTIONS
// ====================================================

/// Length (magnitude) of a 2D vector
/// [x], [y]: Vector components
/// Returns: √(x² + y²)
late final double Function(double x, double y) length;

/// Squared length of a 2D vector (faster, avoids sqrt)
/// [x], [y]: Vector components
/// Returns: x² + y²
late final double Function(double x, double y) lengthSq;

/// Dot product of two 2D vectors
/// [x1], [y1]: First vector
/// [x2], [y2]: Second vector
/// Returns: x1×x2 + y1×y2
late final double Function(double x1, double y1, double x2, double y2) dot;

/// Euclidean distance between two 2D points
/// [x1], [y1]: First point
/// [x2], [y2]: Second point
/// Returns: √((x2-x1)² + (y2-y1)²)
late final double Function(double x1, double y1, double x2, double y2) distance;

/// Squared Euclidean distance (faster, avoids sqrt)
/// [x1], [y1]: First point
/// [x2], [y2]: Second point
/// Returns: (x2-x1)² + (y2-y1)²
late final double Function(double x1, double y1, double x2, double y2) distanceSq;

// ====================================================
// POWER FUNCTIONS
// ====================================================

/// Integer power (exponentiation by squaring)
/// [base]: Base value
/// [exponent]: Integer exponent
/// Returns: base^exponent
/// Note: Handles negative exponents correctly (returns 1/base^|exponent|)
late final double Function(double base, int exponent) intPow;

// ====================================================
// VALUE REMAPPING FUNCTIONS
// ====================================================

/// Linear remapping from one range to another
/// [value]: Input value
/// [inMin], [inMax]: Source range
/// [outMin], [outMax]: Target range
/// Returns: value mapped linearly from [inMin, inMax] to [outMin, outMax]
/// Formula: outMin + (value - inMin) × (outMax - outMin) / (inMax - inMin)
late final double Function(double value, double inMin, double inMax, double outMin, double outMax) remap;

/// Normalizes value to [0, 1] range (inverse of expand)
/// [value]: Input value
/// [min]: Minimum of original range
/// [max]: Maximum of original range
/// Returns: (value - min) / (max - min)
late final double Function(double value, double min, double max) unit;

/// Expands normalized value from [0, 1] to arbitrary range (inverse of unit)
/// [value]: Normalized value [0, 1]
/// [min]: Minimum of target range
/// [max]: Maximum of target range
/// Returns: min + value × (max - min)
late final double Function(double value, double min, double max) expand;

// ====================================================
// EASING FUNCTIONS (for animations)
// ====================================================

/// Smoothstep easing (cubic interpolation)
/// [t]: Input in range [0, 1]
/// Returns: 3t² - 2t³
/// Properties: Smooth start/end, zero derivative at boundaries
late final double Function(double t) smoothstep;

/// Smootherstep easing (quintic interpolation)
/// [t]: Input in range [0, 1]
/// Returns: 6t⁵ - 15t⁴ + 10t³
/// Properties: Even smoother than smoothstep, zero 1st/2nd derivatives at boundaries
late final double Function(double t) smootherstep;

/// Quadratic ease-in (starts slow, accelerates)
/// [t]: Input in range [0, 1]
/// Returns: t²
late final double Function(double t) easeIn;

/// Quadratic ease-out (starts fast, decelerates)
/// [t]: Input in range [0, 1]
/// Returns: 1 - (1-t)²
late final double Function(double t) easeOut;

/// Cubic ease-in-out (smooth acceleration and deceleration)
/// [t]: Input in range [0, 1]
/// Returns: 4t³ if t < 0.5, otherwise 1 - ½(-2t+2)³
late final double Function(double t) easeInOut;

// ====================================================
// BEZIER CURVE FUNCTIONS
// ====================================================

/// Cubic Bezier curve evaluation
/// [p0]: Start point (t=0)
/// [p1]: First control point
/// [p2]: Second control point
/// [p3]: End point (t=1)
/// [t]: Parameter in range [0, 1]
/// Returns: Point on Bezier curve at parameter t
/// Formula: (1-t)³p0 + 3(1-t)²t p1 + 3(1-t)t² p2 + t³ p3
late final double Function(double p0, double p1, double p2, double p3, double t) cubicBezier;

// ====================================================
// NOISE FUNCTION (Perlin-like gradient noise)
// ====================================================

/// 2D gradient noise (Perlin-style)
/// [x], [y]: Input coordinates
/// [seed]: Random seed for deterministic noise
/// Returns: Noise value in range [-1, 1]
/// Properties: Smooth, tileable, deterministic with same seed
/// Note: seed 0 will always use genseed() for random seed
late final double Function(double x, double y, int seed) noise;

// ====================================================
// ROUGH/FAST APPROXIMATE FUNCTIONS (r-prefix)
// Use when speed is more important than accuracy
// ====================================================

/// Fast exponential approximation (~0.1% error)
/// 2-3x faster than exp(), suitable for graphics and games
/// [x]: Exponent
/// Returns: Approximate e^x
late final double Function(double x) rexp;

/// Fast natural logarithm approximation (~0.01% error)
/// 2x faster than log(), uses polynomial approximation
/// [x]: Positive value
/// Returns: Approximate ln(x)
late final double Function(double x) rlog;

/// Fast base-10 logarithm approximation
/// Derived from rlog()
/// [x]: Positive value
/// Returns: Approximate log₁₀(x)
late final double Function(double x) rlog10;

/// Fast inverse square root (Quake III algorithm)
/// ~3x faster than 1.0/sqrt(x), famous bit manipulation trick
/// [x]: Positive value
/// Returns: Approximate 1/√x
late final double Function(double x) risqrt;

/// Fast square root using inverse sqrt approximation
/// ~2x faster than sqrt(), one Newton iteration
/// [x]: Non-negative value
/// Returns: Approximate √x
late final double Function(double x) rsqrt;

/// Fast sine approximation (Bhaskara I, ~0.5% max error)
/// ~3x faster than sin(), periodic with range [-1, 1]
/// [x]: Angle in radians
/// Returns: Approximate sin(x)
late final double Function(double x) rsin;

/// Fast cosine approximation (uses rsin)
/// [x]: Angle in radians
/// Returns: Approximate cos(x) = rsin(π/2 - x)
late final double Function(double x) rcos;

/// Fast tangent approximation (sin/cos ratio)
/// [x]: Angle in radians
/// Returns: Approximate tan(x) = rsin(x)/rcos(x)
late final double Function(double x) rtan;

/// Fast arcsine approximation
/// [x]: Value in range [-1, 1]
/// Returns: Approximate arcsin(x) in radians [-π/2, π/2]
late final double Function(double x) rasin;

/// Fast arccosine approximation
/// [x]: Value in range [-1, 1]
/// Returns: Approximate arccos(x) in radians [0, π]
late final double Function(double x) racos;

/// Fast arctangent approximation (11th degree polynomial)
/// ~2x faster than atan(), maximum error ~0.003%
/// [x]: Input value
/// Returns: Approximate arctan(x) in radians [-π/2, π/2]
late final double Function(double x) ratan;

/// Fast two-argument arctangent
/// Handles all quadrants correctly
/// [y]: Y coordinate
/// [x]: X coordinate
/// Returns: Approximate atan2(y, x) in radians [-π, π]
late final double Function(double y, double x) ratan2;

/// Fast power approximation for graphics
/// Uses rexp(exponent × rlog(x))
/// [x]: Base
/// [exponent]: Power
/// Returns: Approximate x^exponent
late final double Function(double x, double exponent) rpow;

/// Fast hypotenuse approximation (avoids overflow)
/// ~2x faster than hypot()
/// [x]: First side
/// [y]: Second side
/// Returns: Approximate √(x² + y²)
late final double Function(double x, double y) rhypot;

// ====================================================
// ACCURATE STANDARD LIBRARY FUNCTIONS
// Use when IEEE 754 precision is required
// ====================================================

/// Standard sine function (accurate)
/// [x]: Angle in radians
/// Returns: sin(x)
late final double Function(double x) sin;

/// Standard cosine function (accurate)
/// [x]: Angle in radians
/// Returns: cos(x)
late final double Function(double x) cos;

/// Standard tangent function (accurate)
/// [x]: Angle in radians
/// Returns: tan(x)
late final double Function(double x) tan;

/// Standard arcsine function (accurate)
/// [x]: Value in range [-1, 1]
/// Returns: arcsin(x) in radians
late final double Function(double x) asin;

/// Standard arccosine function (accurate)
/// [x]: Value in range [-1, 1]
/// Returns: arccos(x) in radians
late final double Function(double x) acos;

/// Standard arctangent function (accurate)
/// [x]: Input value
/// Returns: arctan(x) in radians
late final double Function(double x) atan;

/// Standard two-argument arctangent (accurate)
/// [y]: Y coordinate
/// [x]: X coordinate
/// Returns: atan2(y, x) in radians
late final double Function(double y, double x) atan2;

/// Standard exponential function (accurate)
/// [x]: Exponent
/// Returns: e^x
late final double Function(double x) exp;

/// Standard natural logarithm (accurate)
/// [x]: Positive value
/// Returns: ln(x)
late final double Function(double x) log;

/// Standard base-10 logarithm (accurate)
/// [x]: Positive value
/// Returns: log₁₀(x)
late final double Function(double x) log10;

/// Standard square root (accurate)
/// [x]: Non-negative value
/// Returns: √x
late final double Function(double x) sqrt;

/// Standard power function (accurate)
/// [x]: Base
/// [y]: Exponent
/// Returns: x^y
late final double Function(double x, double y) pow;

/// Standard hypotenuse (accurate, overflow-safe)
/// [x]: First side
/// [y]: Second side
/// Returns: √(x² + y²)
late final double Function(double x, double y) hypot;

void _loadVariables() {
  initTime      = _lib.lookup<c.Uint64>('_initTime').value;
  lastSeed      = _lib.lookup<c.Uint64>('_rseed').value;
  _randomState  = _lib.lookup<c.Uint64>('_rstate').value;
}

void _loadFunctions() {
  _init = _lib.lookupFunction<
    c.Void Function(),
    void Function()
    >('${_p}init');
    
  now = _lib.lookupFunction<
    c.Uint64 Function(),
    int Function()
    >('${_p}now');
  
  uptime = _lib.lookupFunction<
    c.Uint64 Function(),
    int Function()
    >('${_p}uptime');
    
  clock = _lib.lookupFunction<
    c.Uint64 Function(),
    int Function()
    >('${_p}clock');
    
  genseed = _lib.lookupFunction<
    c.Uint64 Function(),
    int Function()
    >('${_p}genseed');
    
  seed = _lib.lookupFunction<
    c.Void Function(c.Uint64 seed),
    void Function(int seed)
    >('${_p}seed');
    
  random = _lib.lookupFunction<
    c.Double Function(),
    double Function()
    >('${_p}random');
    
  randomInt = _lib.lookupFunction<
    c.Int32 Function(c.Int32 max),
    int Function(int max)
    >('${_p}randomInt');
    
  randomBool = _lib.lookupFunction<
    c.Bool Function(),
    bool Function()
    >('${_p}randomBool');
    
  randomByte = _lib.lookupFunction<
    c.Uint8 Function(),
    int Function()
    >('${_p}randomByte');
  
  final _randomBytesC = _lib.lookupFunction<
    c.Void Function(c.Pointer<c.Uint8> buffer, c.Uint64 size),
    void Function(c.Pointer<c.Uint8> buffer, int size)
    >('${_p}randomBytes', isLeaf: true);
  
  randomBytes = (size) {
    // Allocate native memory using C lib malloc
    final pointer = _malloc(size).cast<c.Uint8>();
    
    try {
      // Call C function
      _randomBytesC(pointer, size);
      
      // Copy bytes to Dart list
      return pointer.asTypedList(size);
    } finally {
      // free the memory
      _free(pointer.cast<c.Void>());
    }
  };
    
  min = _lib.lookupFunction<
    c.Double Function(c.Double a, c.Double b),
    double Function(double a, double b)
    >('${_p}min');
    
  max = _lib.lookupFunction<
    c.Double Function(c.Double a, c.Double),
    double Function(double a, double b)
    >('${_p}max');
    
  med = _lib.lookupFunction<
    c.Double Function(c.Double a, c.Double b, c.Double c),
    double Function(double a, double b, double c)
    >('${_p}med');
    
  clamp = _lib.lookupFunction<
    c.Double Function(c.Double value, c.Double min, c.Double max),
    double Function(double value, double min, double max)
    >('${_p}clamp');
    
  abs = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}abs');
    
  sign = _lib.lookupFunction<
    c.Int32 Function(c.Double x),
    int Function(double x)
    >('${_p}sign');
    
  floor = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}floor');
    
  ceil = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}ceil');
    
  trunc = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}trunc');
    
  round = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}round');
    
  snap = _lib.lookupFunction<
    c.Double Function(c.Double x, c.Double y),
    double Function(double x, double y)
    >('${_p}snap');
    
  snapOffset = _lib.lookupFunction<
    c.Double Function(c.Double x, c.Double y, c.Double offset),
    double Function(double x, double y, double offset)
    >('${_p}snapOffset');
    
  lerp = _lib.lookupFunction<
    c.Double Function(c.Double a, c.Double b, c.Double t),
    double Function(double a, double b, double t)
    >('${_p}lerp');
    
  mod = _lib.lookupFunction<
    c.Double Function(c.Double a, c.Double b),
    double Function(double a, double b)
    >('${_p}mod');
    
  remainder = _lib.lookupFunction<
    c.Double Function(c.Double a, c.Double b),
    double Function(double a, double b)
    >('${_p}remainder');
    
  wrap = _lib.lookupFunction<
    c.Double Function(c.Double a, c.Double b),
    double Function(double a, double b)
    >('${_p}wrap');
    
  wrapRange = _lib.lookupFunction<
    c.Double Function(c.Double value, c.Double min, c.Double max),
    double Function(double value, double min, double max)
    >('${_p}wrapRange');
    
  step = _lib.lookupFunction<
    c.Double Function(c.Double edge, c.Double x),
    double Function(double edge, double x)
    >('${_p}step');
    
  factorial = _lib.lookupFunction<
    c.Uint64 Function(c.Int32 n),
    int Function(int n)
    >('${_p}factorial');
    
  binomial = _lib.lookupFunction<
    c.Uint64 Function(c.Int32 n, c.Int32 k),
    int Function(int n, int k)
    >('${_p}binomial');
    
  toRadians = _lib.lookupFunction<
    c.Double Function(c.Double degrees),
    double Function(double degrees)
    >('${_p}toRadians');
    
  toDegrees = _lib.lookupFunction<
    c.Double Function(c.Double radians),
    double Function(double radians)
    >('${_p}toDegrees');
    
  length = _lib.lookupFunction<
    c.Double Function(c.Double x, c.Double y),
    double Function(double x, double y)
    >('${_p}length');
    
  lengthSq = _lib.lookupFunction<
    c.Double Function(c.Double x, c.Double y),
    double Function(double x, double y)
    >('${_p}lengthSq');
    
  dot = _lib.lookupFunction<
    c.Double Function(c.Double x1, c.Double y1, c.Double x2, c.Double y2),
    double Function(double x1, double y1, double x2, double y2)
    >('${_p}dot');
    
  distance = _lib.lookupFunction<
    c.Double Function(c.Double x1, c.Double y1, c.Double x2, c.Double y2),
    double Function(double x1, double y1, double x2, double y2)
    >('${_p}distance');
    
  distanceSq = _lib.lookupFunction<
    c.Double Function(c.Double x1, c.Double y1, c.Double x2, c.Double y2),
    double Function(double x1, double y1, double x2, double y2)
    >('${_p}distanceSq');
    
  intPow = _lib.lookupFunction<
    c.Double Function(c.Double base, c.Int32 exponent),
    double Function(double base, int exponent)
    >('${_p}intPow');
    
  remap = _lib.lookupFunction<
    c.Double Function(c.Double value, c.Double inMin, c.Double inMax, c.Double outMin, c.Double outMax),
    double Function(double value, double inMin, double inMax, double outMin, double outMax)
    >('${_p}remap');
    
  unit = _lib.lookupFunction<
    c.Double Function(c.Double value, c.Double min, c.Double max),
    double Function(double value, double min, double max)
    >('${_p}unit');
    
  expand = _lib.lookupFunction<
    c.Double Function(c.Double value, c.Double min, c.Double max),
    double Function(double value, double min, double max)
    >('${_p}expand');
    
  smoothstep = _lib.lookupFunction<
    c.Double Function(c.Double t),
    double Function(double t)
    >('${_p}smoothstep');
    
  smootherstep = _lib.lookupFunction<
    c.Double Function(c.Double t),
    double Function(double t)
    >('${_p}smootherstep');
    
  easeIn = _lib.lookupFunction<
    c.Double Function(c.Double t),
    double Function(double t)
    >('${_p}easeIn');
    
  easeOut = _lib.lookupFunction<
    c.Double Function(c.Double t),
    double Function(double t)
    >('${_p}easeOut');
    
  easeInOut = _lib.lookupFunction<
    c.Double Function(c.Double t),
    double Function(double t)
    >('${_p}easeInOut');
    
  cubicBezier = _lib.lookupFunction<
    c.Double Function(c.Double p0, c.Double p1, c.Double p2, c.Double p3, c.Double t),
    double Function(double p0, double p1, double p2, double p3, double t)
    >('${_p}cubicBezier');
    
  noise = _lib.lookupFunction<
    c.Double Function(c.Double x, c.Double y, c.Uint64 seed),
    double Function(double x, double y, int seed)
    >('${_p}noise');
    
  rexp = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}rexp');
    
  rlog = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}rlog');
    
  rlog10 = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}rlog10');
    
  risqrt = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}risqrt');
    
  rsqrt = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}rsqrt');
    
  rsin = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}rsin');
    
  rcos = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}rcos');
    
  rtan = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}rtan');
    
  rasin = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}rasin');
    
  racos = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}racos');
    
  ratan = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}ratan');
    
  ratan2 = _lib.lookupFunction<
    c.Double Function(c.Double y, c.Double x),
    double Function(double y, double x)
    >('${_p}ratan2');
    
  rpow = _lib.lookupFunction<
    c.Double Function(c.Double x, c.Double exponent),
    double Function(double x, double exponent)
    >('${_p}rpow');
    
  rhypot = _lib.lookupFunction<
    c.Double Function(c.Double x, c.Double y),
    double Function(double x, double y)
    >('${_p}rhypot');
    
  sin = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}sin');
    
  cos = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}cos');
    
  tan = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}tan');
    
  asin = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}asin');
    
  acos = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}acos');
    
  atan = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}atan');
    
  atan2 = _lib.lookupFunction<
    c.Double Function(c.Double y, c.Double x),
    double Function(double y, double x)
    >('${_p}atan2');
    
  exp = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}exp');
    
  log = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}log');
    
  log10 = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}log10');
    
  sqrt = _lib.lookupFunction<
    c.Double Function(c.Double x),
    double Function(double x)
    >('${_p}sqrt');
    
  pow = _lib.lookupFunction<
    c.Double Function(c.Double x, c.Double y),
    double Function(double x, double y)
    >('${_p}pow');
    
  hypot = _lib.lookupFunction<
    c.Double Function(c.Double x, c.Double y),
    double Function(double x, double y)
    >('${_p}hypot');
}
