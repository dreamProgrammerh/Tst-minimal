import 'dart:math' as Math;
import '../../utils/fmath.dart' as fMath;

import '../../runtime/context.dart';
import '../../runtime/values.dart';

Math.Random _rand = Math.Random();

void mathSeedFeed(int seed) {
  _rand = Math.Random(seed);
}

final List<(String, int, BuiltinFunction)> mathFuncs = [
  ('random', -1, (args) {
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
  
  ('seed', 1, (args) {
    final x = args[0].asFloat();
    mathSeedFeed(x.toInt());
    return args[0];
  }),
  
  ('max', -1, (args) {
    if (args.length < 2) {
      RuntimeState.error('max need at least 2 arguments');
      return InvalidValue.instance;
    }
    
    return args.kthElement(-1, (a, b) => a.asFloat().compareTo(b.asFloat()));
  }),
  
  ('min', -1, (args) {
    if (args.length < 2) {
      RuntimeState.error('min need at least 2 arguments');
      return InvalidValue.instance;
    }
    
    return args.kthElement(1, (a, b) => a.asFloat().compareTo(b.asFloat()));
  }),
  
  ('med', -1, (args) {
    if (args.length < 3) {
      RuntimeState.error('med need at least 3 arguments');
      return InvalidValue.instance;
    }
    
    return args.kthElement(0, (a, b) => a.asFloat().compareTo(b.asFloat()));
  }),
  
  ('sum', -1, (args) {
    if (args.length < 2) {
      RuntimeState.error('sum need at least 2 arguments');
      return InvalidValue.instance;
    }
    
    return FloatValue(args.fold(0.0, (a, b) => a + b.asFloat()));
  }),
  
  ('avg', -1, (args) {
    if (args.length < 2) {
      RuntimeState.error('avg need at least 2 arguments');
      return InvalidValue.instance;
    }
    
    final sum = args.fold(0.0, (a, b) => a + b.asFloat());
    return FloatValue(sum / args.length);
  }),
  
  ('clamp', 3, (args) {
    final x = args[0].asFloat();
    final min = args[0].asFloat();
    final max = args[0].asFloat();
    return FloatValue(x.clamp(min, max));
  }),
  
  ('round', 1, (args) {
    final x = args[0].asFloat();
    return IntValue(x.round());
  }),
  
  ('ceil', 1, (args) {
    final x = args[0].asFloat();
    return IntValue(x.ceil());
  }),
  
  ('floor', 1, (args) {
    final x = args[0].asFloat();
    return IntValue(x.floor());
  }),
  
  ('abs', 1, (args) {
    final x = args[0].asFloat();
    return FloatValue(x.abs());
  }),
  
  ('sign', 1, (args) {
    final x = args[0].asFloat();
    return IntValue(x.sign.toInt());
  }),
  
  ('snap', 2, (args) {
    final x = args[0].asFloat();
    final y = args[1].asFloat();
    return FloatValue(fMath.snap(x, y));
  }),
  
  ('snapOffset', 3, (args) {
    final x = args[0].asFloat();
    final y = args[1].asFloat();
    final offset = args[2].asFloat();
    return FloatValue(fMath.snapOffset(x, y, offset));
  }),
  
  ('unit', 3, (args) {
    final x = args[0].asFloat();
    final min = args[0].asFloat();
    final max = args[0].asFloat();
    return FloatValue(fMath.unit(x, min, max));
  }),
  
  ('expand', 3, (args) {
    final x = args[0].asFloat();
    final min = args[0].asFloat();
    final max = args[0].asFloat();
    return FloatValue(fMath.expand(x, min, max));
  }),
  
  ('degree', 1, (args) {
    final x = args[0].asFloat();
    return FloatValue(x * fMath.radToDeg);
  }),
  
  ('radian', 1, (args) {
    final x = args[0].asFloat();
    return FloatValue(x * fMath.degToRad);
  }),
  
  ('lerp', 3, (args) {
    final intLerp = args[0] is IntValue && args[1] is IntValue;
    
    final a = args[0].asFloat();
    final b = args[1].asFloat();
    final t = args[2].asFloat();
    
    return intLerp
      ? IntValue((a + (b - a) * t).toInt())
      : FloatValue(a + (b - a) * t);
  }),
  
  ('pow', 2, (args) {
    final intPow = args[0] is IntValue && args[1] is IntValue;
    
    final x = args[0].asFloat();
    final e = args[1].asFloat();
    
    return intPow
      ? FloatValue(fMath.pow(x, e).toDouble())
      : IntValue(fMath.intPow(x, e.toInt()).toInt());
  }),
  
  ('sqrt', 1, (args) {
    final x = args[0].asFloat();
    return FloatValue(fMath.sqrt(x));
  }),
  
  ('exp', 1, (args) {
    final x = args[0].asFloat();
    return FloatValue(fMath.exp(x));
  }),
  
  ('log', 1, (args) {
    final x = args[0].asFloat();
    return FloatValue(fMath.log(x));
  }),
  
  ('sin', 1, (args) {
    final x = args[0].asFloat();
    return FloatValue(fMath.sin(x));
  }),
  
  ('cos', 1, (args) {
    final x = args[0].asFloat();
    return FloatValue(fMath.cos(x));
  }),
  
  ('tan', 1, (args) {
    final x = args[0].asFloat();
    return FloatValue(fMath.tan(x));
  }),
  
  ('asin', 1, (args) {
    final x = args[0].asFloat();
    return FloatValue(fMath.asin(x));
  }),
  
  ('acos', 1, (args) {
    final x = args[0].asFloat();
    return FloatValue(fMath.acos(x));
  }),
  
  ('atan', 1, (args) {
    final x = args[0].asFloat();
    return FloatValue(fMath.atan(x));
  }),
  
  ('atan2', 2, (args) {
    final y = args[0].asFloat();
    final x = args[1].asFloat();
    return FloatValue(fMath.atan2(y, x));
  }),
];
