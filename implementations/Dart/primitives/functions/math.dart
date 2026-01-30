// TODO: clean this file and add most of fmath functions

import 'dart:math' as Math;
import '../../utils/fmath.dart' as fMath;

import '../../runtime/context.dart';
import '../../runtime/values.dart';

Math.Random _rand = Math.Random();

void randomSeed(int seed) {
  _rand = Math.Random(seed);
}

final List<(String, int, BuiltinFunction)> mathFuncs = [
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
  
  ('random', -1, (args) {
    if (args.length > 2) {
      RuntimeState.error('random cannot accept more than 2 arguments');
      return InvalidValue.instance;
    }
    
    if (args.length == 0)
      return FloatValue(_rand.nextDouble());
      
    if (args.length == 1) {
      double max = args[0].asFloat();
      return args[0] is IntValue
        ? IntValue(_rand.nextInt(max.toInt()))
        : FloatValue(_rand.nextDouble() * max);
    
    } // else args.length == 2
    
    double min = args[0].asFloat();
    double max = args[1].asFloat();
    
    return args[0] is IntValue && args[1] is IntValue
      ? IntValue(_rand.nextInt((max - min).toInt()) + min.toInt())
      : FloatValue(_rand.nextDouble() * (max - min) + min);
  }),
  
  ('lerp', 3, (args) {
    bool intLerp = args[0] is IntValue && args[1] is IntValue;
    
    double a = args[0].asFloat();
    double b = args[1].asFloat();
    double t = args[2].asFloat();
    
    return intLerp
      ? IntValue((a + (b - a) * t).toInt())
      : FloatValue(a + (b - a) * t);
  }),
  
  ('pow', 2, (args) {
    bool intLerp = args[0] is IntValue && args[1] is IntValue;
    
    double x = args[0].asFloat();
    double e = args[1].asFloat();
    
    return intLerp
      ? FloatValue(Math.pow(x, e).toDouble())
      : IntValue(Math.pow(x, e).toInt());
  }),
  
  ('sqrt', 1, (args) {
    double x = args[0].asFloat();
    return FloatValue(Math.sqrt(x));
  }),
  
  ('round', 1, (args) {
    double x = args[0].asFloat();
    return IntValue(x.round());
  }),
  
  ('ceil', 1, (args) {
    double x = args[0].asFloat();
    return IntValue(x.ceil());
  }),
  
  ('floor', 1, (args) {
    double x = args[0].asFloat();
    return IntValue(x.floor());
  }),
  
  ('degrees', 1, (args) {
    double x = args[0].asFloat();
    return FloatValue((x / 180) * Math.pi);
  }),
  
  ('radian', 1, (args) {
    double x = args[0].asFloat();
    return FloatValue((x / Math.pi) * 180);
  }),
  
  ('sin', 1, (args) {
    double x = args[0].asFloat();
    return FloatValue(Math.sin(x));
  }),
  
  ('asin', 1, (args) {
    double x = args[0].asFloat();
    return FloatValue(Math.asin(x));
  }),
  
  ('cos', 1, (args) {
    double x = args[0].asFloat();
    return FloatValue(Math.cos(x));
  }),
  
  ('acos', 1, (args) {
    double x = args[0].asFloat();
    return FloatValue(Math.acos(x));
  }),
  
  ('tan', 1, (args) {
    double x = args[0].asFloat();
    return FloatValue(Math.tan(x));
  }),
  
  ('atan', 1, (args) {
    double x = args[0].asFloat();
    return FloatValue(Math.atan(x));
  }),
  
  ('atan2', 2, (args) {
    double y = args[0].asFloat();
    double x = args[1].asFloat();
    return FloatValue(Math.atan2(y, x));
  }),
  
  ('seed', 1, (args) {
    double x = args[0].asFloat();
    randomSeed(x.toInt());
    return args[0];
  }),
];
