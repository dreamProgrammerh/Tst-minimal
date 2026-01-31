import 'dart:math' as Math;

import '../../runtime/context.dart';
import '../../runtime/values.dart';
import '../../utils/color.dart' as Colors;

Math.Random _rand = Math.Random();

void colorSeedFeed(int seed) {
  _rand = Math.Random(seed);
}

final List<(String, int, BuiltinFunction)> colorFuncs = [
  ('randomColor', 0, (_) {
    return IntValue(0xFF000000 | _rand.nextInt(0xFFFFFF));
  }),

  ('seedColor', 1, (args) {
    double x = args[0].asFloat();
    colorSeedFeed(x.toInt());
    return args[0];
  }),

  ('rgba', 4, (args) {
    final r = args[0].asInt() & 0xff;
    final g = args[1].asInt() & 0xff;
    final b = args[2].asInt() & 0xff;
    final a = args[3].asInt() & 0xff;

    return IntValue((a << 24) | (r << 16) | (g << 8) | b);
  }),

  ('rgbo', 4, (args) {
    final r = args[0].asInt() & 0xff;
    final g = args[1].asInt() & 0xff;
    final b = args[2].asInt() & 0xff;
    final a = (args[3].asFloat() * 0xff).clamp(0, 0xff).toInt();

    return IntValue((a << 24) | (r << 16) | (g << 8) | b);
  }),

  ('rgb', 3, (args) {
    final r = args[0].asInt() & 0xff;
    final g = args[1].asInt() & 0xff;
    final b = args[2].asInt() & 0xff;

    return IntValue((0xff << 24) | (r << 16) | (g << 8) | b);
  }),

  ('hslo', 4, (args) {
    final h = args[0].asFloat();
    final s = args[1].asFloat();
    final l = args[2].asFloat();
    final o = args[3].asFloat();

    return IntValue(Colors.hsl(h, s, l, o));
  }),

  ('hsl', 3, (args) {
    final h = args[0].asFloat();
    final s = args[1].asFloat();
    final l = args[2].asFloat();

    return IntValue(Colors.hsl(h, s, l));
  }),

  ('hsvo', 4, (args) {
    final h = args[0].asFloat();
    final s = args[1].asFloat();
    final v = args[2].asFloat();
    final o = args[3].asFloat();

    return IntValue(Colors.hsv(h, s, v, o));
  }),

  ('hsv', 3, (args) {
    final h = args[0].asFloat();
    final s = args[1].asFloat();
    final v = args[2].asFloat();

    return IntValue(Colors.hsv(h, s, v));
  }),

  ('cymka', 3, (args) {
    final c = args[0].asInt();
    final m = args[1].asInt();
    final y = args[2].asInt();
    final k = args[3].asInt();
    final a = args[4].asInt();

    return IntValue(Colors.cmyk(c, m, y, k, a));
  }),

  ('cymk', 3, (args) {
    final c = args[0].asInt();
    final m = args[1].asInt();
    final y = args[2].asInt();
    final k = args[3].asInt();

    return IntValue(Colors.cmyk(c, m, y, k));
  }),

  ('hex', 1, (args) {
    final code = args[0].asInt();

    return IntValue(Colors.hex(code));
  }),

  ('lighten', 2, (args) {
    final color = args[0].asInt();
    final percent = args[1].asFloat();

    return IntValue(Colors.lighten(color, percent));
  }),

  ('darken', 2, (args) {
    final color = args[0].asInt();
    final percent = args[1].asFloat();

    return IntValue(Colors.darken(color, percent));
  }),

  ('brightness', 2, (args) {
    final color = args[0].asInt();
    final factor = args[1].asFloat();

    return IntValue(Colors.brightness(color, factor));
  }),

  ('saturation', 2, (args) {
    final color = args[0].asInt();
    final factor = args[1].asFloat();

    return IntValue(Colors.brightness(color, factor));
  }),

  ('hue', 2, (args) {
    final color = args[0].asInt();
    final angle = args[1].asFloat();

    return IntValue(Colors.brightness(color, angle));
  }),

  ('shiftHue', 2, (args) {
    final color = args[0].asInt();
    final radians = args[1].asFloat();

    return IntValue(Colors.shiftHue(color, radians));
  }),

  ('temperature', 2, (args) {
    final color = args[0].asInt();
    final temp = args[1].asFloat();

    return IntValue(Colors.temperature(color, temp));
  }),

  ('shiftTemperature', 2, (args) {
    final color = args[0].asInt();
    final temp = args[1].asFloat();

    return IntValue(Colors.shiftTemperature(color, temp));
  }),

  ('mix', 3, (args) {
    final color1 = args[0].asInt();
    final color2 = args[1].asInt();
    final t = args[2].asFloat();

    return IntValue(Colors.mix(color1, color2, t));
  }),

  ('blend', 2, (args) {
    final color1 = args[0].asInt();
    final color2 = args[1].asInt();

    return IntValue(Colors.blendScreen(color1, color2));
  }),

  ('invert', 1, (args) {
    final color = args[0].asInt();

    return IntValue(Colors.invert(color));
  }),

  ('grayscale', 1, (args) {
    final color = args[0].asInt();

    return IntValue(Colors.grayscale(color));
  }),

  ('neon', 1, (args) {
    final color = args[0].asInt();

    return IntValue(Colors.neon(color));
  }),

  ('pastel', 1, (args) {
    final color = args[0].asInt();

    return IntValue(Colors.pastel(color));
  }),

  ('pressa', 1, (args) {
    final color = args[0].asInt();

    return IntValue(Colors.pressa(color));
  }),

  ('complement', 1, (args) {
    final color = args[0].asInt();

    return IntValue(Colors.complement(color));
  }),

  ('tint', 2, (args) {
    final color = args[0].asInt();
    final delta = args[1].asInt();

    return IntValue(Colors.tint(color, delta));
  }),

  ('tone', 2, (args) {
    final color = args[0].asInt();
    final delta = args[1].asInt();

    return IntValue(Colors.tone(color, delta));
  }),

  ('shift', 2, (args) {
    final color = args[0].asInt();
    final pos = args[1].asInt(); // 0-255

    return IntValue(Colors.shift(color, pos));
  }),

  ('opacity', 2, (args) {
    final color = args[0].asInt();
    final percent = args[1].asFloat();

    return IntValue(Colors.opacity(color, percent));
  }),

  ('contrast', 2, (args) {
    final color = args[0].asInt();
    final factor = args[1].asFloat();

    return IntValue(Colors.contrast(color, factor));
  }),

  ('vibrance', 2, (args) {
    final color = args[0].asInt();
    final amount = args[1].asFloat();

    return IntValue(Colors.vibrance(color, amount));
  }),

  ('glow', 2, (args) {
    final color = args[0].asInt();
    final intensity = args[1].asFloat();

    return IntValue(Colors.glow(color, intensity));
  }),

  ('distance', 2, (args) {
    final color1 = args[0].asInt();
    final color2 = args[1].asInt();

    return FloatValue(Colors.distance(color1, color2));
  }),

  ('difference', 2, (args) {
    final color1 = args[0].asInt();
    final color2 = args[1].asInt();

    return FloatValue(Colors.difference(color1, color2));
  }),
  
  ('isDark', 1, (args) {
    final color = args[0].asInt();

    return IntValue(Colors.isDark(color) ? 1 : 0);
  }),
  
  ('isGray', 1, (args) {
    final color = args[0].asInt();

    return IntValue(Colors.isGray(color) ? 1 : 0);
  }),
  
  ('isLight', 1, (args) {
    final color = args[0].asInt();

    return IntValue(Colors.isLight(color) ? 1 : 0);
  }),
  
  ('isNeon', 1, (args) {
    final color = args[0].asInt();

    return IntValue(Colors.isNeon(color) ? 1 : 0);
  }),
  
  ('isPastel', 1, (args) {
    final color = args[0].asInt();

    return IntValue(Colors.isPastel(color) ? 1 : 0);
  }),
  
  ('isVibrant', 1, (args) {
    final color = args[0].asInt();

    return IntValue(Colors.isVibrant(color) ? 1 : 0);
  }),
  
  ('isSimilar', 3, (args) {
    final color1 = args[0].asInt();
    final color2 = args[1].asInt();
    final threshold = args[2].asFloat();

    return IntValue(Colors.isSimilar(color1, color2, threshold) ? 1 : 0);
  }),
];
