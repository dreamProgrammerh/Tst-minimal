import 'dart:math' as Math;

import '../runtime/context.dart';
import '../runtime/values.dart';
import '../utils/colors.dart' as Colors;

Math.Random _rand = Math.Random();

void randomSeed(int seed) {
  _rand = Math.Random(seed);
}

final List<(String, BuiltinFunction)> builtinFunc = [
  // Math
  ('max', (args) {
    if (args.length < 2) {
      RuntimeState.error('max need at least 2 arguments');
      return InvalidValue.instance;
    }
    
    int index = 0;
    double value = args[index].asFloat();
    
    for (int i = 1; i < args.length; i++) {
      double newVal = args[i].asFloat();
      if (newVal > value) {
        index = i;
        value = newVal;
      }
    }
    
    return args[index];
  }),
  
  ('min', (args) {
    if (args.length < 2) {
      RuntimeState.error('min need at least 2 arguments');
      return InvalidValue.instance;
    }
    
    int index = 0;
    double value = args[index].asFloat();
    
    for (int i = 1; i < args.length; i++) {
      double newVal = args[i].asFloat();
      if (value > newVal) {
        index = i;
        value = newVal;
      }
    }
    
    return args[index];
  }),
  
  ('sum', (args) {
    if (args.length < 2) {
      RuntimeState.error('sum need at least 2 arguments');
      return InvalidValue.instance;
    }
    
    bool isInt = args[0] is IntValue;
    double sum = args[0].asFloat();
    
    for (int i = 1; i < args.length; i++) {
      sum += args[i].asFloat();
      if (isInt) isInt = args[i] is IntValue;
    }
    
    return isInt
      ? IntValue(sum.toInt())
      : FloatValue(sum.toDouble());
  }),
  
  ('avg', (args) {
    if (args.length < 2) {
      RuntimeState.error('avg need at least 2 arguments');
      return InvalidValue.instance;
    }
    
    bool isInt = args[0] is IntValue;
    double sum = args[0].asFloat();
    
    for (int i = 1; i < args.length; i++) {
      sum += args[i].asFloat();
      if (isInt) isInt = args[i] is IntValue;
    }
    
    sum /= args.length;
    
    return isInt
      ? IntValue(sum.toInt())
      : FloatValue(sum.toDouble());
  }),
  
  ('random', (args) {
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
];

final List<(String, int, BuiltinFunction)> builtinFuncArgCount = [
  // Convert
  ('int', 1, (args) {
    double x = args[0].asFloat();
    return IntValue(x.toInt());
  }),
  
  ('float', 1, (args) {
    double x = args[0].asFloat();
    return FloatValue(x);
  }),
  
  ('bool', 1, (args) {
    double x = args[0].asFloat();
    return IntValue(x == 0 ? 0 : 1);
  }),
  
  // Math
  ('lerp', 3, (args) {
    bool intLerp = args[0] is IntValue && args[1] is IntValue;
    
    double a = args[0].asFloat();
    double b = args[1].asFloat();
    double t = args[2].asFloat();
    
    return intLerp
      ? IntValue(Colors.lerpInt(a.toInt(), b.toInt(), t))
      : FloatValue(Colors.lerpDouble(a, b, t));
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
  
  ('seed', 1, (args) {
    double x = args[0].asFloat();
    randomSeed(x.toInt());
    return args[0];
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
  
  // Color Variants
  ('randomColor', 0, (_) {
    return IntValue(Colors.rgba(
      _rand.nextInt(255),
      _rand.nextInt(255),
      _rand.nextInt(255),
    ));
  }),
  
  ('rgba', 4, (args) {
    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;
    int a = args[3].asInt() & 0xff;

    return IntValue((a << 24) | (r << 16) | (g << 8) | b);
  }),
  
  ('rgbo', 4, (args) {
    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;
    int a = (args[3].asFloat() * 0xff).clamp(0, 0xff).toInt();

    return IntValue((a << 24) | (r << 16) | (g << 8) | b);
  }),

  ('rgb', 3, (args) {
    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;

    return IntValue((0xff << 24) | (r << 16) | (g << 8) | b);
  }),

  ('hex', 1, (args) {
    int code = args[0].asInt();

    return IntValue(Colors.hex(code));
  }),
  
  ('hslo', 4, (args) {
    double h = args[0].asFloat();
    double s = args[1].asFloat();
    double l = args[2].asFloat();
    double o = args[2].asFloat();

    return IntValue(Colors.hsl(h, s, l, o));
  }),
  
  ('hsl', 3, (args) {
    double h = args[0].asFloat();
    double s = args[1].asFloat();
    double l = args[2].asFloat();

    return IntValue(Colors.hsl(h, s, l));
  }),
  
  ('hsvo', 4, (args) {
    double h = args[0].asFloat();
    double s = args[1].asFloat();
    double v = args[2].asFloat();
    double o = args[2].asFloat();

    return IntValue(Colors.hsv(h, s, v, o));
  }),
  
  ('hsv', 3, (args) {
    double h = args[0].asFloat();
    double s = args[1].asFloat();
    double v = args[2].asFloat();

    return IntValue(Colors.hsv(h, s, v));
  }),
  
  // Color Manipulations
  ('lighten', 2, (args) {
    int color = args[0].asInt();
    double percent = args[1].asFloat();

    return IntValue(Colors.lightenColor(color, percent));
  }),
  
  ('darken', 2, (args) {
    int color = args[0].asInt();
    double percent = args[1].asFloat();

    return IntValue(Colors.darkenColor(color, percent));
  }),
  
  ('shiftHue', 2, (args) {
    int color = args[0].asInt();
    double degrees = args[1].asFloat();

    return IntValue(Colors.rotateHue(color, degrees));
  }),
  
  ('mix', 3, (args) {
    int color1 = args[0].asInt();
    int color2 = args[1].asInt();
    double t = args[2].asFloat();

    return IntValue(Colors.colorMix(color1, color2, t));
  }),
  
  ('pressa', 1, (args) {
    int color = args[0].asInt();

    return IntValue(Colors.premultiplyAlpha(color));
  }),
  
  ('invert', 1, (args) {
    int color = args[0].asInt();

    return IntValue(Colors.invertColor(color));
  }),
  
  ('grayscale', 1, (args) {
    int color = args[0].asInt();

    return IntValue(Colors.toGrayscale(color));
  }),
  
  // Color Settings
  ('opacity', 2, (args) {
    int color = args[0].asInt();
    double percent = args[1].asFloat();

    return IntValue(Colors.setOpacity(color, percent));
  }),
  
  ('contrast', 2, (args) {
    int color = args[0].asInt();
    double factor = args[1].asFloat();

    return IntValue(Colors.adjustContrast(color, factor));
  }),
  
  ('hue', 2, (args) {
    int color = args[0].asInt();
    double degrees = args[1].asFloat();

    return IntValue(Colors.adjustHue(color, degrees));
  }),
  
  ('saturation', 2, (args) {
    int color = args[0].asInt();
    double factor = args[1].asFloat();

    return IntValue(Colors.adjustSaturation(color, factor));
  }),
  
  ('brightness', 2, (args) {
    int color = args[0].asInt();
    int delta = args[1].asInt();

    return IntValue(Colors.adjustBrightness(color, delta));
  }),
];