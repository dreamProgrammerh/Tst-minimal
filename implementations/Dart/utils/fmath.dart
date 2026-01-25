import 'dart:ffi' as c;
import 'dart:io';
import 'dart:typed_data';

const _p = 'fmath_'; // prefix
final String? _libraryPath =
        Platform.isWindows ? "lib/fastMath.dll"
      : Platform.isMacOS ? "lib/fastMath.dylib"
      : Platform.isLinux ? "lib/fastMath.so"
      : null;
      
late final c.DynamicLibrary _lib;

void load_fmathLib() {
  if (_libraryPath == null)
    throw UnsupportedError("Unsupported Operating System: ${Platform.operatingSystem}");
  
  _lib = c.DynamicLibrary.open(_libraryPath!);
  
  _loadFunctions();
  _init();
}

final _malloc = c.DynamicLibrary.process().lookupFunction<
  c.Pointer<c.Void> Function(c.IntPtr size),
  c.Pointer<c.Void> Function(int size)
>('malloc');

final _free = c.DynamicLibrary.process().lookupFunction<
  c.Void Function(c.Pointer<c.Void> ptr),
  void Function(c.Pointer<c.Void> ptr)
>('free');

late final void Function() _init;

late final int Function() now;

late final int Function() uptime;

late final int Function() clock;

late final int Function() genseed;

late final void Function(int seed) seed;

late final double Function() random;

late final int Function(int max) randomInt;

late final bool Function() randomBool;

late final int Function() randomByte;

late final Uint8List Function(int size) randomBytes;

late final double Function(double a, double b) min;

late final double Function(double a, double b) max;

late final double Function(double a, double b, double c) med;

late final double Function(double value, double min, double max) clamp;

late final double Function(double x) abs;

late final int Function(double x) sign;

late final double Function(double x) floor;

late final double Function(double x) ceil;

late final double Function(double x) trunc;

late final double Function(double x) round;

late final double Function(double x, double y) snap;

late final double Function(double x, double y, double offset) snapOffset;

late final double Function(double a, double b, double t) lerp;

late final double Function(double a, double b) mod;

late final double Function(double a, double b) remainder;

late final double Function(double a, double b) wrap;

late final double Function(double value, double min, double max) wrapRange;

late final double Function(double edge, double x) step;

late final int Function(int n) factorial;

late final int Function(int n, int k) binomial;

late final double Function(double degrees) toRadians;

late final double Function(double radians) toDegrees;

late final double Function(double x, double y) length;

late final double Function(double x, double y) lengthSq;

late final double Function(double x1, double y1, double x2, double y2) dot;

late final double Function(double x1, double y1, double x2, double y2) distance;

late final double Function(double x1, double y1, double x2, double y2) distanceSq;

late final double Function(double base, int exponent) intPow;

late final double Function(double value, double inMin, double inMax, double outMin, double outMax) remap;

late final double Function(double value, double min, double max) unit;

late final double Function(double value, double min, double max) expand;

late final double Function(double t) smoothstep;

late final double Function(double t) smootherstep;

late final double Function(double t) easeIn;

late final double Function(double t) easeOut;

late final double Function(double t) easeInOut;

late final double Function(double p0, double p1, double p2, double p3, double t) cubicBezier;

late final double Function(double x, double y, int seed) noise;

late final double Function(double x) rexp;

late final double Function(double x) rlog;

late final double Function(double x) rlog10;

late final double Function(double x) risqrt;

late final double Function(double x) rsqrt;

late final double Function(double x) rsin;

late final double Function(double x) rcos;

late final double Function(double x) rtan;

late final double Function(double x) rasin;

late final double Function(double x) racos;

late final double Function(double x) ratan;

late final double Function(double y, double x) ratan2;

late final double Function(double x, double exponent) rpow;

late final double Function(double x, double y) rhypot;

late final double Function(double x) sin;

late final double Function(double x) cos;

late final double Function(double x) tan;

late final double Function(double x) asin;

late final double Function(double x) acos;

late final double Function(double x) atan;

late final double Function(double y, double x) atan2;

late final double Function(double x) exp;

late final double Function(double x) log;

late final double Function(double x) log10;

late final double Function(double x) sqrt;

late final double Function(double x, double y) pow;

late final double Function(double x, double y) hypot;


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
