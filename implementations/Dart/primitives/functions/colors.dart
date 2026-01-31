import 'dart:math' as Math;

import '../../runtime/context.dart';
import '../../runtime/values.dart';
import '../../utils/color.dart' as Colors;

Math.Random _rand = Math.Random();
void colorSeedFeed(int seed) => _rand = Math.Random(seed);

final List<BuiltinSignature> colorFuncs = [
  ('randomColor', [], [], null, (_) {
    return IntValue(0xFF000000 | _rand.nextInt(0xFFFFFF));
  }),

  ('seedColor', [AT_int], ["seed"], null, (args) {
    colorSeedFeed(args[0].asInt());
    return args[0];
  }),

  ('rgba',
    [AT_int, AT_int, AT_int, AT_int],
    ["r", "g", "b", "a"], null, (args) {
    final r = args[0].asInt() & 0xff;
    final g = args[1].asInt() & 0xff;
    final b = args[2].asInt() & 0xff;
    final a = args[3].asInt() & 0xff;

    return IntValue((a << 24) | (r << 16) | (g << 8) | b);
  }),

  ('rgbo',
    [AT_int, AT_int, AT_int, AT_float],
    ["r", "g", "b", "o"], null, (args) {
    final r = args[0].asInt() & 0xff;
    final g = args[1].asInt() & 0xff;
    final b = args[2].asInt() & 0xff;
    final a = (args[3].asFloat() * 0xff).clamp(0, 0xff).toInt();

    return IntValue((a << 24) | (r << 16) | (g << 8) | b);
  }),

  ('rgb',
    [AT_int, AT_int, AT_int],
    ["r", "g", "b"], null, (args) {
    final r = args[0].asInt() & 0xff;
    final g = args[1].asInt() & 0xff;
    final b = args[2].asInt() & 0xff;

    return IntValue((0xff << 24) | (r << 16) | (g << 8) | b);
  }),

  ('hslo',
    [AT_float, AT_float, AT_float, AT_float],
    ["h", "s", "l", "o"], null, (args) {
    final h = args[0].asFloat();
    final s = args[1].asFloat();
    final l = args[2].asFloat();
    final o = args[3].asFloat();

    return IntValue(Colors.hsl(h, s, l, o));
  }),

  ('hsl',
    [AT_float, AT_float, AT_float],
    ["h", "s", "l"], null, (args) {
    final h = args[0].asFloat();
    final s = args[1].asFloat();
    final l = args[2].asFloat();

    return IntValue(Colors.hsl(h, s, l));
  }),

  ('hsvo',
    [AT_float, AT_float, AT_float, AT_float],
    ["h", "s", "v", "o"], null, (args) {
    final h = args[0].asFloat();
    final s = args[1].asFloat();
    final v = args[2].asFloat();
    final o = args[3].asFloat();

    return IntValue(Colors.hsv(h, s, v, o));
  }),

  ('hsv',
    [AT_float, AT_float, AT_float],
    ["h", "s", "v"], null, (args) {
    final h = args[0].asFloat();
    final s = args[1].asFloat();
    final v = args[2].asFloat();

    return IntValue(Colors.hsv(h, s, v));
  }),

  ('cymka',
    [AT_int, AT_int, AT_int, AT_int, AT_int],
    ["c", "m", "y", "k", "a"], null, (args) {
    final c = args[0].asInt();
    final m = args[1].asInt();
    final y = args[2].asInt();
    final k = args[3].asInt();
    final a = args[4].asInt();

    return IntValue(Colors.cmyk(c, m, y, k, a));
  }),

  ('cymk',
    [AT_int, AT_int, AT_int, AT_int],
    ["c", "m", "y", "k"], null, (args) {
    final c = args[0].asInt();
    final m = args[1].asInt();
    final y = args[2].asInt();
    final k = args[3].asInt();

    return IntValue(Colors.cmyk(c, m, y, k));
  }),

  ('hex',
    [AT_int],
    ["hex"], null, (args) {
    final code = args[0].asInt();

    return IntValue(Colors.hex(code));
  }),

  ('lighten',
    [AT_int, AT_float],
    ["color", "percentage"], null, (args) {
    final color = args[0].asInt();
    final percentage = args[1].asFloat();

    return IntValue(Colors.lighten(color, percentage));
  }),

  ('darken',
    [AT_int, AT_float],
    ["color", "percentage"], null, (args) {
    final color = args[0].asInt();
    final percentage = args[1].asFloat();

    return IntValue(Colors.darken(color, percentage));
  }),

  ('brightness',
    [AT_int, AT_float],
    ["color", "percentage"], null, (args) {
    final color = args[0].asInt();
    final percentage = args[1].asFloat();

    return IntValue(Colors.brightness(color, percentage));
  }),

  ('saturation',
    [AT_int, AT_float],
    ["color", "percentage"], null, (args) {
    final color = args[0].asInt();
    final percentage = args[1].asFloat();

    return IntValue(Colors.brightness(color, percentage));
  }),

  ('hue',
    [AT_int, AT_float],
    ["color", "angle"], null, (args) {
    final color = args[0].asInt();
    final angle = args[1].asFloat();

    return IntValue(Colors.brightness(color, angle));
  }),

  ('shiftHue',
    [AT_int, AT_float],
    ["color", "radians"], null, (args) {
    final color = args[0].asInt();
    final radians = args[1].asFloat();

    return IntValue(Colors.shiftHue(color, radians));
  }),

  ('temperature',
    [AT_int, AT_float],
    ["color", "temperature"], null, (args) {
    final color = args[0].asInt();
    final temp = args[1].asFloat();

    return IntValue(Colors.temperature(color, temp));
  }),

  ('shiftTemperature',
    [AT_int, AT_float],
    ["color", "temperature"], null, (args) {
    final color = args[0].asInt();
    final temp = args[1].asFloat();

    return IntValue(Colors.shiftTemperature(color, temp));
  }),

  ('mix',
    [AT_int, AT_int, AT_float],
    ["colorA", "colorB", "t"], null, (args) {
    final colorA = args[0].asInt();
    final colorB = args[1].asInt();
    final t = args[2].asFloat();

    return IntValue(Colors.mix(colorA, colorB, t));
  }),

  ('blend',
    [AT_int, AT_int],
    ["colorA", "colorB"], null, (args) {
    final colorA = args[0].asInt();
    final colorB = args[1].asInt();

    return IntValue(Colors.blendScreen(colorA, colorB));
  }),

  ('invert', [AT_int], ["color"], null, (args) {
    return IntValue(Colors.invert(args[0].asInt()));
  }),

  ('grayscale', [AT_int], ["color"], null, (args) {
    return IntValue(Colors.grayscale(args[0].asInt()));
  }),

  ('neon', [AT_int], ["color"], null, (args) {
    return IntValue(Colors.neon(args[0].asInt()));
  }),

  ('pastel', [AT_int], ["color"], null, (args) {
    return IntValue(Colors.pastel(args[0].asInt()));
  }),

  ('pressa', [AT_int], ["color"], null, (args) {
    return IntValue(Colors.pressa(args[0].asInt()));
  }),

  ('complement', [AT_int], ["color"], null, (args) {
    return IntValue(Colors.complement(args[0].asInt()));
  }),

  ('tint',
    [AT_int, AT_float],
    ["color", "percentage"], null, (args) {
    final color = args[0].asInt();
    final percentage = args[1].asFloat();

    return IntValue(Colors.tint(color, percentage));
  }),

  ('tone',
    [AT_int, AT_float],
    ["color", "percentage"], null, (args) {
    final color = args[0].asInt();
    final percentage = args[1].asFloat();

    return IntValue(Colors.tone(color, percentage));
  }),

  ('shade',
    [AT_int, AT_float],
    ["color", "percentage"], null, (args) {
    final color = args[0].asInt();
    final percentage = args[1].asFloat();

    return IntValue(Colors.shade(color, percentage));
  }),

  ('shift',
    [AT_int, AT_int],
    ["color", "position"], null, (args) {
    final color = args[0].asInt();
    final pos = args[1].asInt(); // 0-255

    return IntValue(Colors.shift(color, pos));
  }),

  ('opacity',
    [AT_int, AT_float],
    ["color", "percentage"], null, (args) {
    final color = args[0].asInt();
    final percent = args[1].asFloat();

    return IntValue(Colors.opacity(color, percent));
  }),

  ('contrast',
    [AT_int, AT_float],
    ["color", "factor"], null, (args) {
    final color = args[0].asInt();
    final factor = args[1].asFloat();

    return IntValue(Colors.contrast(color, factor));
  }),

  ('vibrance',
    [AT_int, AT_float],
    ["color", "amount"], null, (args) {
    final color = args[0].asInt();
    final amount = args[1].asFloat();

    return IntValue(Colors.vibrance(color, amount));
  }),

  ('glow',
    [AT_int, AT_float],
    ["color", "intensity"], null, (args) {
    final color = args[0].asInt();
    final intensity = args[1].asFloat();

    return IntValue(Colors.glow(color, intensity));
  }),

  ('distance',
    [AT_int, AT_int],
    ["colorA", "colorB"], null, (args) {
    final colorA = args[0].asInt();
    final colorB = args[1].asInt();

    return FloatValue(Colors.distance(colorA, colorB));
  }),

  ('difference',
    [AT_int, AT_int],
    ["colorA", "colorB"], null, (args) {
    final colorA = args[0].asInt();
    final colorB = args[1].asInt();

    return FloatValue(Colors.difference(colorA, colorB));
  }),
  
  ('isDark',
    [AT_int],
    ["color"], null, (args) {
    return IntValue(Colors.isDark(args[0].asInt()) ? 1 : 0);
  }),
  
  ('isGray',
    [AT_int],
    ["color"], null, (args) {
    return IntValue(Colors.isGray(args[0].asInt()) ? 1 : 0);
  }),
  
  ('isLight',
    [AT_int],
    ["color"], null, (args) {
    return IntValue(Colors.isLight(args[0].asInt()) ? 1 : 0);
  }),
  
  ('isNeon',
    [AT_int],
    ["color"], null, (args) {
    return IntValue(Colors.isNeon(args[0].asInt()) ? 1 : 0);
  }),
  
  ('isPastel',
    [AT_int],
    ["color"], null, (args) {
    return IntValue(Colors.isPastel(args[0].asInt()) ? 1 : 0);
  }),
  
  ('isVibrant',
    [AT_int],
    ["color"], null, (args) {
    return IntValue(Colors.isVibrant(args[0].asInt()) ? 1 : 0);
  }),
  
  ('isSimilar',
    [AT_int, AT_int, AT_float],
    ["colorA", "colorB", "threshold"], null, (args) {
    final colorA = args[0].asInt();
    final colorB = args[1].asInt();
    final threshold = args[2].asFloat();

    return IntValue(Colors.isSimilar(colorA, colorB, threshold) ? 1 : 0);
  }),
];
