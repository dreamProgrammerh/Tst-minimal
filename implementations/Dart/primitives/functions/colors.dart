// TODO: add most of color.dart functions and use cleaner api

import 'dart:math' as Math;

import '../../runtime/context.dart';
import '../../runtime/values.dart';
import '../../utils/color.dart' as Colors;

Math.Random _rand = Math.Random();

void randomSeed(int seed) {
  _rand = Math.Random(seed);
}

final List<(String, int, BuiltinFunction)> colorFuncs = [
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

    return IntValue(Colors.lighten(color, percent));
  }),
  
  ('darken', 2, (args) {
    int color = args[0].asInt();
    double percent = args[1].asFloat();

    return IntValue(Colors.darken(color, percent));
  }),
  
  ('shiftHue', 2, (args) {
    int color = args[0].asInt();
    double degrees = args[1].asFloat();

    return IntValue(Colors.shiftHue(color, degrees));
  }),
  
  ('mix', 3, (args) {
    int color1 = args[0].asInt();
    int color2 = args[1].asInt();
    double t = args[2].asFloat();

    return IntValue(Colors.mix(color1, color2, t));
  }),
  
  ('pressa', 1, (args) {
    int color = args[0].asInt();

    return IntValue(Colors.pressa(color));
  }),
  
  ('invert', 1, (args) {
    int color = args[0].asInt();

    return IntValue(Colors.invert(color));
  }),
  
  ('grayscale', 1, (args) {
    int color = args[0].asInt();

    return IntValue(Colors.grayscale(color));
  }),
  
  // Color Settings
  ('opacity', 2, (args) {
    int color = args[0].asInt();
    double percent = args[1].asFloat();

    return IntValue(Colors.opacity(color, percent));
  }),
  
  ('contrast', 2, (args) {
    int color = args[0].asInt();
    double factor = args[1].asFloat();

    return IntValue(Colors.contrast(color, factor));
  }),
  
  ('hue', 2, (args) {
    int color = args[0].asInt();
    double degrees = args[1].asFloat();

    return IntValue(Colors.hue(color, degrees));
  }),
  
  ('saturation', 2, (args) {
    int color = args[0].asInt();
    double factor = args[1].asFloat();

    return IntValue(Colors.saturation(color, factor));
  }),
  
  ('brightness', 2, (args) {
    int color = args[0].asInt();
    int delta = args[1].asInt();

    return IntValue(Colors.brightness(color, delta.toDouble()));
  }),
];