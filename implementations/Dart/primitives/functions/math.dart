import 'dart:math' as Math;
import '../../utils/fmath.dart' as fMath;

import '../../runtime/context.dart';
import '../../runtime/values.dart';

Math.Random _rand = Math.Random();
void mathSeedFeed(int seed) => _rand = Math.Random(seed);

final List<BuiltinSignature> mathFuncs = [
  ('random', null, null, null, (args) {
    if (args.length > 2) {
      RuntimeState.error('random cannot accept more than 2 arguments');
      return InvalidValue.instance;
    }
    
    if (args.isEmpty) return FloatValue(_rand.nextDouble());
      
    if (args.length == 1) {
      final max = args[0].asFloat();
      return args[0] is IntValue
        ? IntValue(_rand.nextInt(max.toInt()))
        : FloatValue(_rand.nextDouble() * max);
    
    } // else args.length == 2
    
    final min = args[0].asFloat();
    final max = args[1].asFloat();
    
    return args[0] is IntValue && args[1] is IntValue
      ? IntValue(_rand.nextInt((max - min).toInt()) + min.toInt())
      : FloatValue(_rand.nextDouble() * (max - min) + min);
  }),
  
  ('seed', [AT_int], ["seed"], null, (args) {
    final x = args[0].asFloat();
    mathSeedFeed(x.toInt());
    return args[0];
  }),
  
  ('max', null, null, null, (args) {
    if (args.length < 2) {
      RuntimeState.error('max need at least 2 arguments');
      return InvalidValue.instance;
    }
    
    return args.kthElement(-1, (a, b) => a.asFloat().compareTo(b.asFloat()));
  }),
  
  ('min', null, null, null, (args) {
    if (args.length < 2) {
      RuntimeState.error('min need at least 2 arguments');
      return InvalidValue.instance;
    }
    
    return args.kthElement(1, (a, b) => a.asFloat().compareTo(b.asFloat()));
  }),
  
  ('med', null, null, null, (args) {
    if (args.length < 3) {
      RuntimeState.error('med need at least 3 arguments');
      return InvalidValue.instance;
    }
    
    return args.kthElement(0, (a, b) => a.asFloat().compareTo(b.asFloat()));
  }),
  
  ('sum', null, null, null, (args) {
    if (args.length < 2) {
      RuntimeState.error('sum need at least 2 arguments');
      return InvalidValue.instance;
    }
    
    return FloatValue(args.fold(0.0, (a, b) => a + b.asFloat()));
  }),
  
  ('avg', null, null, null, (args) {
    if (args.length < 2) {
      RuntimeState.error('avg need at least 2 arguments');
      return InvalidValue.instance;
    }
    
    final sum = args.fold(0.0, (a, b) => a + b.asFloat());
    return FloatValue(sum / args.length);
  }),
  
  ('clamp',
    [AT_int | AT_float, AT_int | AT_float, AT_int | AT_float],
    ["x", "min", "max"], null, (args) {
    final x = args[0].asFloat();
    final min = args[1].asFloat();
    final max = args[2].asFloat();
    return FloatValue(x.clamp(min, max));
  }),
  
  ('round', [AT_int | AT_float], ["x"], null, (args) {
    return IntValue(args[0].asFloat().round());
  }),
  
  ('ceil', [AT_int | AT_float], ["x"], null, (args) {
    return IntValue(args[0].asFloat().ceil());
  }),
  
  ('floor', [AT_int | AT_float], ["x"], null, (args) {
    return IntValue(args[0].asFloat().floor());
  }),
  
  ('abs', [AT_int | AT_float], ["x"], null, (args) {
    return FloatValue(args[0].asFloat().abs());
  }),
  
  ('sign', [AT_int | AT_float], ["x"], null, (args) {
    return IntValue(args[0].asFloat().sign.toInt());
  }),
  
  ('snap', [AT_int | AT_float, AT_int | AT_float], ["x", "y"], null, (args) {
    final x = args[0].asFloat();
    final y = args[1].asFloat();
    return args[1] is IntValue
      ? IntValue(fMath.snap(x, y).toInt())
      : FloatValue(fMath.snap(x, y));
  }),
  
  ('snapOffset',
    [AT_int | AT_float, AT_int | AT_float, AT_int | AT_float],
    ["x", "y", "offset"], null, (args) {
    final x = args[0].asFloat();
    final y = args[1].asFloat();
    final offset = args[2].asFloat();
    return args[1] is IntValue && args[2] is IntValue
      ? IntValue(fMath.snapOffset(x, y, offset).toInt())
      : FloatValue(fMath.snapOffset(x, y, offset));
  }),
  
  ('unit',
    [AT_int | AT_float, AT_int | AT_float, AT_int | AT_float],
    ["x", "min", "max"], null, (args) {
    final x = args[0].asFloat();
    final min = args[1].asFloat();
    final max = args[2].asFloat();
    return args[1] is IntValue && args[2] is IntValue
      ? IntValue(fMath.unit(x, min, max).toInt())
      : FloatValue(fMath.unit(x, min, max));
  }),
  
  ('expand',
    [AT_int | AT_float, AT_int | AT_float, AT_int | AT_float],
    ["x", "min", "max"], null, (args) {
    final x = args[0].asFloat();
    final min = args[1].asFloat();
    final max = args[2].asFloat();
    return FloatValue(fMath.expand(x, min, max));
  }),
  
  ('degree', [AT_int | AT_float], ["radian"], null, (args) {
    return args[0] is IntValue
    ? IntValue((args[0].asInt() * fMath.radToDeg).toInt())
    : FloatValue(args[0].asFloat() * fMath.radToDeg);
  }),
  
  ('radian', [AT_int | AT_float], ["degree"], null, (args) {
    return args[0] is IntValue
    ? IntValue((args[0].asInt() * fMath.degToRad).toInt())
    : FloatValue(args[0].asFloat() * fMath.degToRad);
  }),
  
  ('lerp',
    [AT_int | AT_float, AT_int | AT_float, AT_float],
    ["a", "b", "t"], null, (args) {
    final a = args[0].asFloat();
    final b = args[1].asFloat();
    final t = args[2].asFloat();
    
    return args[0] is IntValue && args[1] is IntValue
      ? IntValue((a + (b - a) * t).toInt())
      : FloatValue(a + (b - a) * t);
  }),
  
  ('pow',
    [AT_int | AT_float, AT_int | AT_float],
    ["x", "e"], null, (args) {
    final x = args[0].asFloat();
    final e = args[1].asFloat();
    
    return args[0] is IntValue && args[1] is IntValue
      ? FloatValue(fMath.pow(x, e).toDouble())
      : IntValue(fMath.intPow(x, e.toInt()).toInt());
  }),
  
  ('sqrt', [AT_int | AT_float], ["x"], null, (args) {
    return FloatValue(fMath.sqrt(args[0].asFloat()));
  }),
  
  ('exp', [AT_int | AT_float], ["x"], null, (args) {
    return FloatValue(fMath.exp(args[0].asFloat()));
  }),
  
  ('log', [AT_int | AT_float], ["x"], null, (args) {
    return FloatValue(fMath.log(args[0].asFloat()));
  }),
  
  ('sin', [AT_int | AT_float], ["x"], null, (args) {
    return FloatValue(fMath.sin(args[0].asFloat()));
  }),
  
  ('cos', [AT_int | AT_float], ["x"], null, (args) {
    return FloatValue(fMath.cos(args[0].asFloat()));
  }),
  
  ('tan', [AT_int | AT_float], ["x"], null, (args) {
    return FloatValue(fMath.tan(args[0].asFloat()));
  }),
  
  ('asin', [AT_int | AT_float], ["x"], null, (args) {
    return FloatValue(fMath.asin(args[0].asFloat()));
  }),
  
  ('acos', [AT_int | AT_float], ["x"], null, (args) {
    return FloatValue(fMath.acos(args[0].asFloat()));
  }),
  
  ('atan', [AT_int | AT_float], ["x"], null, (args) {
    return FloatValue(fMath.atan(args[0].asFloat()));
  }),
  
  ('atan2',
    [AT_int | AT_float, AT_int | AT_float],
    ["y", "x"], null, (args) {
    final y = args[0].asFloat();
    final x = args[1].asFloat();
    return FloatValue(fMath.atan2(y, x));
  }),
];
