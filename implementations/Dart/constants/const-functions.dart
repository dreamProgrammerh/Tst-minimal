import '../runtime/context.dart';
import '../runtime/values.dart';
import '../utils/colors.dart' as Colors;

final List<(String, BuiltinFunction)> builtinFunc = [];

final List<(String, int, BuiltinFunction)> builtinFuncArgCount = [
    // Color Variants
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
  
      return IntValue(Colors.rotateHue(color, degrees));
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