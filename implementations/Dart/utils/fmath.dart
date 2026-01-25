import 'dart:ffi' as c;
import 'dart:io';

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
  
  _init();
}

final _init = _lib.lookupFunction<
  c.Void Function(),
  void Function()
  >('${_p}init');
  
final now = _lib.lookupFunction<
  c.Uint64 Function(),
  int Function()
  >('${_p}now');

final uptime = _lib.lookupFunction<
  c.Uint64 Function(),
  int Function()
  >('${_p}uptime');
  
final clock = _lib.lookupFunction<
  c.Uint64 Function(),
  int Function()
  >('${_p}clock');
  
final genseed = _lib.lookupFunction<
  c.Uint64 Function(),
  int Function()
  >('${_p}genseed');
  
final seed = _lib.lookupFunction<
  c.Void Function(c.Uint64 seed),
  void Function(int seed)
  >('${_p}seed');
  
final random = _lib.lookupFunction<
  c.Double Function(),
  double Function()
  >('${_p}random');
  
final randomInt = _lib.lookupFunction<
  c.Int32 Function(c.Int32 max),
  int Function(int max)
  >('${_p}randomInt');
  
final randomBool = _lib.lookupFunction<
  c.Bool Function(),
  bool Function()
  >('${_p}randomBool');
  
final randomByte = _lib.lookupFunction<
  c.Uint8 Function(),
  int Function()
  >('${_p}randomByte');
  
final min = _lib.lookupFunction<
  c.Double Function(c.Double a, c.Double b),
  double Function(double a, double b)
  >('${_p}min');
  
final max = _lib.lookupFunction<
  c.Double Function(c.Double a, c.Double),
  double Function(double a, double b)
  >('${_p}max');
  
final med = _lib.lookupFunction<
  c.Double Function(c.Double a, c.Double b, c.Double c),
  double Function(double a, double b, double c)
  >('${_p}med');
  

final clamp = _lib.lookupFunction<
  c.Double Function(c.Double value, c.Double min, c.Double max),
  double Function(double value, double min, double max)
  >('${_p}clamp');
  
final abs = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}abs');
  
final sign = _lib.lookupFunction<
  c.Int32 Function(c.Double x),
  int Function(double x)
  >('${_p}sign');
  
final floor = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}floor');
  
final ceil = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}ceil');
  
final trunc = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}trunc');
  
final round = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}round');
  
final snap = _lib.lookupFunction<
  c.Double Function(c.Double x, c.Double y),
  double Function(double x, double y)
  >('${_p}snap');
  
final snapOffset = _lib.lookupFunction<
  c.Double Function(c.Double x, c.Double y, c.Double offset),
  double Function(double x, double y, double offset)
  >('${_p}snapOffset');
  
final lerp = _lib.lookupFunction<
  c.Double Function(c.Double a, c.Double b, c.Double t),
  double Function(double a, double b, double t)
  >('${_p}lerp');
  
final mod = _lib.lookupFunction<
  c.Double Function(c.Double a, c.Double b),
  double Function(double a, double b)
  >('${_p}mod');
  
final remainder = _lib.lookupFunction<
  c.Double Function(c.Double a, c.Double b),
  double Function(double a, double b)
  >('${_p}remainder');
  
final wrap = _lib.lookupFunction<
  c.Double Function(c.Double a, c.Double b),
  double Function(double a, double b)
  >('${_p}wrap');
  
final wrapRange = _lib.lookupFunction<
  c.Double Function(c.Double value, c.Double min, c.Double max),
  double Function(double value, double min, double max)
  >('${_p}wrapRange');
  
final step = _lib.lookupFunction<
  c.Double Function(c.Double edge, c.Double x),
  double Function(double edge, double x)
  >('${_p}step');
  
final factorial = _lib.lookupFunction<
  c.Uint64 Function(c.Int32 n),
  int Function(int n)
  >('${_p}factorial');
  
final binomial = _lib.lookupFunction<
  c.Uint64 Function(c.Int32 n, c.Int32 k),
  int Function(int n, int k)
  >('${_p}binomial');
  
final toRadians = _lib.lookupFunction<
  c.Double Function(c.Double degrees),
  double Function(double degrees)
  >('${_p}toRadians');
  
final toDegrees = _lib.lookupFunction<
  c.Double Function(c.Double radians),
  double Function(double radians)
  >('${_p}toDegrees');
  
final length = _lib.lookupFunction<
  c.Double Function(c.Double x, c.Double y),
  double Function(double x, double y)
  >('${_p}length');
  
final lengthSq = _lib.lookupFunction<
  c.Double Function(c.Double x, c.Double y),
  double Function(double x, double y)
  >('${_p}lengthSq');
  
final dot = _lib.lookupFunction<
  c.Double Function(c.Double x1, c.Double y1, c.Double x2, c.Double y2),
  double Function(double x1, double y1, double x2, double y2)
  >('${_p}dot');
  
final distance = _lib.lookupFunction<
  c.Double Function(c.Double x1, c.Double y1, c.Double x2, c.Double y2),
  double Function(double x1, double y1, double x2, double y2)
  >('${_p}distance');
  
final distanceSq = _lib.lookupFunction<
  c.Double Function(c.Double x1, c.Double y1, c.Double x2, c.Double y2),
  double Function(double x1, double y1, double x2, double y2)
  >('${_p}distanceSq');
  
final intPow = _lib.lookupFunction<
  c.Double Function(c.Double base, c.Int32 exponent),
  double Function(double base, int exponent)
  >('${_p}intPow');
  
final remap = _lib.lookupFunction<
  c.Double Function(c.Double value, c.Double inMin, c.Double inMax, c.Double outMin, c.Double outMax),
  double Function(double value, double inMin, double inMax, double outMin, double outMax)
  >('${_p}remap');
  
final unit = _lib.lookupFunction<
  c.Double Function(c.Double value, c.Double min, c.Double max),
  double Function(double value, double min, double max)
  >('${_p}unit');
  
final expand = _lib.lookupFunction<
  c.Double Function(c.Double value, c.Double min, c.Double max),
  double Function(double value, double min, double max)
  >('${_p}expand');
  
final smoothstep = _lib.lookupFunction<
  c.Double Function(c.Double t),
  double Function(double t)
  >('${_p}smoothstep');
  
final smootherstep = _lib.lookupFunction<
  c.Double Function(c.Double t),
  double Function(double t)
  >('${_p}smootherstep');
  
final easeIn = _lib.lookupFunction<
  c.Double Function(c.Double t),
  double Function(double t)
  >('${_p}easeIn');
  
final easeOut = _lib.lookupFunction<
  c.Double Function(c.Double t),
  double Function(double t)
  >('${_p}easeOut');
  
final easeInOut = _lib.lookupFunction<
  c.Double Function(c.Double t),
  double Function(double t)
  >('${_p}easeInOut');
  
final cubicBezier = _lib.lookupFunction<
  c.Double Function(c.Double p0, c.Double p1, c.Double p2, c.Double p3, c.Double t),
  double Function(double p0, double p1, double p2, double p3, double t)
  >('${_p}cubicBezier');
  
final noise = _lib.lookupFunction<
  c.Double Function(c.Double x, c.Double y, c.Uint64 seed),
  double Function(double x, double y, int seed)
  >('${_p}noise');
  
final rexp = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}rexp');
  
final rlog = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}rlog');
  
final rlog10 = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}rlog10');
  
final risqrt = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}risqrt');
  
final rsqrt = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}rsqrt');
  
final rsin = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}rsin');
  
final rcos = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}rcos');
  
final rtan = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}rtan');
  
final rasin = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}rasin');
  
final racos = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}racos');
  
final ratan = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}ratan');
  
final ratan2 = _lib.lookupFunction<
  c.Double Function(c.Double y, c.Double x),
  double Function(double y, double x)
  >('${_p}ratan2');
  
final rpow = _lib.lookupFunction<
  c.Double Function(c.Double x, c.Double exponent),
  double Function(double x, double exponent)
  >('${_p}rpow');
  
final rhypot = _lib.lookupFunction<
  c.Double Function(c.Double x, c.Double y),
  double Function(double x, double y)
  >('${_p}rhypot');
  
final sin = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}sin');
  
final cos = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}cos');
  
final tan = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}tan');
  
final asin = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}asin');
  
final acos = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}acos');
  
final atan = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}atan');
  
final atan2 = _lib.lookupFunction<
  c.Double Function(c.Double y, c.Double x),
  double Function(double y, double x)
  >('${_p}atan2');
  
final exp = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}exp');
  
final log = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}log');
  
final log10 = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}log10');
  
final sqrt = _lib.lookupFunction<
  c.Double Function(c.Double x),
  double Function(double x)
  >('${_p}sqrt');
  
final pow = _lib.lookupFunction<
  c.Double Function(c.Double x, c.Double y),
  double Function(double x, double y)
  >('${_p}pow');
  
final hypot = _lib.lookupFunction<
  c.Double Function(c.Double x, c.Double y),
  double Function(double x, double y)
  >('${_p}hypot');
  