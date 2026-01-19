import '../constants/const-literals.dart' as LITERALS;
import '../utils/colors.dart' as Colors;
import 'context.dart';
import 'values.dart';

void initBuiltin() {
  _initLiterals();
  _initFunctions();
}

void _initLiterals() {
   // Special
  for (final lit in LITERALS.specialLiterals)
    registerLiteral(lit.$1, lit.$2);
  
  // Math
  for (final lit in LITERALS.mathLiterals)
    registerLiteral(lit.$1, lit.$2);
  
  // Colors
  for (final lit in LITERALS.colorLiterals)
    registerLiteral(lit.$1, IntValue(lit.$2));
}

void _initFunctions() {
  // Color Variants
  registerFuncWithArgs('rgba', 4, (args) {
    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;
    int a = args[3].asInt() & 0xff;

    return IntValue((a << 24) | (r << 16) | (g << 8) | b);
  });
  
  registerFuncWithArgs('rgbo', 4, (args) {
    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;
    int a = (args[3].asFloat() * 0xff).clamp(0, 0xff).toInt();

    return IntValue((a << 24) | (r << 16) | (g << 8) | b);
  });

  registerFuncWithArgs('rgb', 3, (args) {
    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;

    return IntValue((0xff << 24) | (r << 16) | (g << 8) | b);
  });

  registerFuncWithArgs('hex', 1, (args) {
    int code = args[0].asInt();

    return IntValue(Colors.hex(code));
  });
  
  registerFuncWithArgs('hslo', 4, (args) {
    double h = args[0].asFloat();
    double s = args[1].asFloat();
    double l = args[2].asFloat();
    double o = args[2].asFloat();

    return IntValue(Colors.hsl(h, s, l, o));
  });
  
  registerFuncWithArgs('hsl', 3, (args) {
    double h = args[0].asFloat();
    double s = args[1].asFloat();
    double l = args[2].asFloat();

    return IntValue(Colors.hsl(h, s, l));
  });
  
  registerFuncWithArgs('hsvo', 4, (args) {
    double h = args[0].asFloat();
    double s = args[1].asFloat();
    double v = args[2].asFloat();
    double o = args[2].asFloat();

    return IntValue(Colors.hsv(h, s, v, o));
  });
  
  registerFuncWithArgs('hsv', 3, (args) {
    double h = args[0].asFloat();
    double s = args[1].asFloat();
    double v = args[2].asFloat();

    return IntValue(Colors.hsv(h, s, v));
  });
  
  // Color Manipulations
  registerFuncWithArgs('lighten', 2, (args) {
    int color = args[0].asInt();
    double percent = args[1].asFloat();

    return IntValue(Colors.lightenColor(color, percent));
  });
  
  registerFuncWithArgs('darken', 2, (args) {
    int color = args[0].asInt();
    double percent = args[1].asFloat();

    return IntValue(Colors.darkenColor(color, percent));
  });
  
  registerFuncWithArgs('mix', 3, (args) {
    int color1 = args[0].asInt();
    int color2 = args[1].asInt();
    double t = args[2].asFloat();

    return IntValue(Colors.colorMix(color1, color2, t));
  });
  
  registerFuncWithArgs('pressa', 1, (args) {
    int color = args[0].asInt();

    return IntValue(Colors.premultiplyAlpha(color));
  });
  
  registerFuncWithArgs('invert', 1, (args) {
    int color = args[0].asInt();

    return IntValue(Colors.invertColor(color));
  });
  
  registerFuncWithArgs('grayscale', 1, (args) {
    int color = args[0].asInt();

    return IntValue(Colors.toGrayscale(color));
  });
  
  // Color Settings
  registerFuncWithArgs('opacity', 2, (args) {
    int color = args[0].asInt();
    double percent = args[1].asFloat();

    return IntValue(Colors.setOpacity(color, percent));
  });
  
  registerFuncWithArgs('contrast', 2, (args) {
    int color = args[0].asInt();
    double factor = args[1].asFloat();

    return IntValue(Colors.adjustContrast(color, factor));
  });
  
  registerFuncWithArgs('hue', 2, (args) {
    int color = args[0].asInt();
    double degrees = args[1].asFloat();

    return IntValue(Colors.rotateHue(color, degrees));
  });
  
  registerFuncWithArgs('saturation', 2, (args) {
    int color = args[0].asInt();
    double factor = args[1].asFloat();

    return IntValue(Colors.adjustSaturation(color, factor));
  });
  
  registerFuncWithArgs('brightness', 2, (args) {
    int color = args[0].asInt();
    int delta = args[1].asInt();

    return IntValue(Colors.adjustBrightness(color, delta));
  });
}