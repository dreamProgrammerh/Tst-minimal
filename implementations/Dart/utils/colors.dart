import 'dart:math' as math;

typedef ARGBColor = int;
enum ShadeAlignment { start, center, end }

ARGBColor rgba(int r, int g, int b, [int a = 255]) =>
    (a << 24) | (r << 16) | (g << 8) | b;

int getA(int c) => (c >> 24) & 0xFF;
int getR(int c) => (c >> 16) & 0xFF;
int getG(int c) => (c >> 8) & 0xFF;
int getB(int c) => c & 0xFF;


ARGBColor rgbo(int r, int g, int b, [double o = 1.00]) =>
    ((o.clamp(0, 1) * 255).round() << 24) | (r << 16) | (g << 8) | b;

// Accepts 0xRRGGBB or 0xAARRGGBB
ARGBColor hex(int value) {
  if (value <= 0xFFFFFF) {
    // no alpha provided → assume opaque
    return 0xFF000000 | value;
  }
  return value;
}

ARGBColor? hexColor(String hex) {
  final o = hex.startsWith('#') ? 1 : 0;
  final len = hex.length - o;
  
  String code;
  
  // Using switch for better performance
  switch (len) {
      case 1:
      final x = hex[o + 0];
      code = 'ff$x$x$x$x$x$x';
      break;
  
      case 2:
      final x = hex[o + 0];
      final y = hex[o + 1];
      code = '$y$y$x$x$x$x$x$x';
      break;
  
      case 3:
      final r = hex[o + 0];
      final g = hex[o + 1];
      final b = hex[o + 2];
      code = 'ff$r$r$g$g$b$b';
      break;
  
      case 4:
      final r = hex[o + 0];
      final g = hex[o + 1];
      final b = hex[o + 2];
      final a = hex[o + 3];
      code = '$a$a$r$r$g$g$b$b';
      break;
  
      case 6:
      final r = hex[o + 0];
      final r_ = hex[o + 1];
      final g = hex[o + 2];
      final g_ = hex[o + 3];
      final b = hex[o + 4];
      final b_ = hex[o + 5];
      code = 'ff$r$r_$g$g_$b$b_';
      break;
  
      case 8:
      final r = hex[o + 0];
      final r_ = hex[o + 1];
      final g = hex[o + 2];
      final g_ = hex[o + 3];
      final b = hex[o + 4];
      final b_ = hex[o + 5];
      final a = hex[o + 6];
      final a_ = hex[o + 7];
      code = '$a$a_$r$r_$g$g_$b$b_';
      break;
  
      default:
        return null;
  }
  
  return ARGBColor.parse(code, radix: 16);
}

ARGBColor hsl(double h, double s, double l, [double o = 1.00]) {
  h = h % 360;
  s = s.clamp(0.0, 1.0);
  l = l.clamp(0.0, 1.0);

  double c = (1 - (2 * l - 1).abs()) * s;
  double x = c * (1 - ((h / 60) % 2 - 1).abs());
  double m = l - c / 2;

  double r = 0, g = 0, b = 0;
  if (h < 60)      { r = c; g = x; }
  else if (h < 120){ r = x; g = c; }
  else if (h < 180){ g = c; b = x; }
  else if (h < 240){ g = x; b = c; }
  else if (h < 300){ r = x; b = c; }
  else             { r = c; b = x; }

  return rgbo(
    ((r + m) * 255).round(),
    ((g + m) * 255).round(),
    ((b + m) * 255).round(),
    o,
  );
}

ARGBColor hsv(double h, double s, double v, [double o = 1.00]) {
  h = h % 360;
  s = s.clamp(0.0, 1.0);
  v = v.clamp(0.0, 1.0);

  double c = v * s;
  double x = c * (1 - ((h / 60) % 2 - 1).abs());
  double m = v - c;

  double r = 0, g = 0, b = 0;
  if (h < 60)      { r = c; g = x; }
  else if (h < 120){ r = x; g = c; }
  else if (h < 180){ g = c; b = x; }
  else if (h < 240){ g = x; b = c; }
  else if (h < 300){ r = x; b = c; }
  else             { r = c; b = x; }

  return rgbo(
    ((r + m) * 255).round(),
    ((g + m) * 255).round(),
    ((b + m) * 255).round(),
    o,
  );
}


ARGBColor darkenColor(ARGBColor color, double percent) {
  final a = getA(color);
  final r = (getR(color) * (1 - percent)).round();
  final g = (getG(color) * (1 - percent)).round();
  final b = (getB(color) * (1 - percent)).round();
  return rgba(r, g, b, a);
}

ARGBColor lightenColor(ARGBColor color, double percent) {
  final a = getA(color);
  final r = (getR(color) + (255 - getR(color)) * percent).round();
  final g = (getG(color) + (255 - getG(color)) * percent).round();
  final b = (getB(color) + (255 - getB(color)) * percent).round();
  return rgba(r, g, b, a);
}

ARGBColor rotateHue(ARGBColor color, double degrees) {
  final a = getA(color);
  double r = getR(color) / 255.0;
  double g = getG(color) / 255.0;
  double b = getB(color) / 255.0;

  final angle = degrees * math.pi / 180.0;
  final cosA = math.cos(angle);
  final sinA = math.sin(angle);

  final nr = r * (0.213 + cosA * 0.787 - sinA * 0.213) +
             g * (0.715 - cosA * 0.715 - sinA * 0.715) +
             b * (0.072 - cosA * 0.072 + sinA * 0.928);

  final ng = r * (0.213 - cosA * 0.213 + sinA * 0.143) +
             g * (0.715 + cosA * 0.285 + sinA * 0.140) +
             b * (0.072 - cosA * 0.072 - sinA * 0.283);

  final nb = r * (0.213 - cosA * 0.213 - sinA * 0.787) +
             g * (0.715 - cosA * 0.715 + sinA * 0.715) +
             b * (0.072 + cosA * 0.928 + sinA * 0.072);

  return rgba(
    (nr.clamp(0.0, 1.0) * 255).round(),
    (ng.clamp(0.0, 1.0) * 255).round(),
    (nb.clamp(0.0, 1.0) * 255).round(),
    a,
  );
}

ARGBColor colorMix(ARGBColor c1, ARGBColor c2, double t) {
  if (t < 0.0) t = 0.0;
  if (t > 1.0) t = 1.0;

  final a = (getA(c1) + (getA(c2) - getA(c1)) * t).round();
  final r = (getR(c1) + (getR(c2) - getR(c1)) * t).round();
  final g = (getG(c1) + (getG(c2) - getG(c1)) * t).round();
  final b = (getB(c1) + (getB(c2) - getB(c1)) * t).round();

  return rgba(r, g, b, a);
}

ARGBColor mixColors(List<ARGBColor> colors, [List<double>? weights]) {
  if (colors.isEmpty) return 0;

  // default: equal weights
  weights ??= List.filled(colors.length, 1.0);

  // Strict check
  assert(weights.length == colors.length, 'weights.length must equal colors.length');

  double total = weights.fold(0.0, (a, b) => a + b);
  if (total == 0) return 0;

  double a = 0, r = 0, g = 0, b = 0;
  for (int i = 0; i < colors.length; i++) {
    final w = weights[i % weights.length];
    a += getA(colors[i]) * w;
    r += getR(colors[i]) * w;
    g += getG(colors[i]) * w;
    b += getB(colors[i]) * w;
  }

  return rgba(
    (r / total).round(),
    (g / total).round(),
    (b / total).round(),
    (a / total).round(),
  );
}

ARGBColor setOpacity(ARGBColor color, double percent) {
  final r = getR(color);
  final g = getG(color);
  final b = getB(color);
  final a = (255 * percent).round().clamp(0, 255);
  return rgba(r, g, b, a);
}

ARGBColor toGrayscale(ARGBColor color) {
  final a = getA(color);
  final r = getR(color);
  final g = getG(color);
  final b = getB(color);
  final gray = (0.299 * r + 0.587 * g + 0.114 * b).round();
  return rgba(gray, gray, gray, a);
}

ARGBColor invertColor(ARGBColor color) {
  final a = getA(color);
  return rgba(255 - getR(color), 255 - getG(color), 255 - getB(color), a);
}

ARGBColor adjustContrast(ARGBColor color, double factor) {
  final a = getA(color);
  int f(int c) => ((c - 128) * factor + 128).clamp(0, 255).round();
  return rgba(f(getR(color)), f(getG(color)), f(getB(color)), a);
}

ARGBColor adjustHue(ARGBColor color, double hueDegrees) { // TODO: use matrix multiplication instead
  int a = getA(color);
  double r = getR(color) / 255.0;
  double g = getG(color) / 255.0;
  double b = getB(color) / 255.0;

  double maxVal = math.max(r, math.max(g, b));
  double minVal = math.min(r, math.min(g, b));
  double delta = maxVal - minVal;

  double h = 0.0;
  double s = 0.0;
  double l = (maxVal + minVal) * 0.5;

  if (delta != 0.0) {
    s = (l < 0.5)
      ? (delta / (maxVal + minVal))
      : (delta / (2.0 - maxVal - minVal));
  }

  hueDegrees = hueDegrees % 360.0;
  if (hueDegrees < 0.0) hueDegrees += 360.0;
  h = hueDegrees;
  
  double c = (1 - (2 * l - 1).abs()) * s;
  double x = c * (1 - ((h / 60) % 2 - 1).abs());
  double m = l - c * 0.5;

  r = g = b = 0;
  if (h < 60)       { r = c; g = x; }
  else if (h < 120) { r = x; g = c; }
  else if (h < 180) { g = c; b = x; }
  else if (h < 240) { g = x; b = c; }
  else if (h < 300) { r = x; b = c; }
  else /* 360 */    { r = c; b = x; }

  return rgba(
    ((r + m) * 255).round(),
    ((g + m) * 255).round(),
    ((b + m) * 255).round(),
    a,
  );
}

ARGBColor adjustSaturation(ARGBColor color, double factor) {
  final a = getA(color);
  final r = getR(color).toDouble();
  final g = getG(color).toDouble();
  final b = getB(color).toDouble();
  final gray = 0.299 * r + 0.587 * g + 0.114 * b;
  int mix(double c) => (gray + (c - gray) * factor).clamp(0, 255).round();
  return rgba(mix(r), mix(g), mix(b), a);
}

ARGBColor adjustBrightness(ARGBColor color, int delta) {
  final a = getA(color);
  int f(int c) => (c + delta).clamp(0, 255);
  return rgba(f(getR(color)), f(getG(color)), f(getB(color)), a);
}

ARGBColor premultiplyAlpha(ARGBColor color) {
  final a = getA(color);
  final factor = a / 255.0;
  return rgba(
    (getR(color) * factor).round(),
    (getG(color) * factor).round(),
    (getB(color) * factor).round(),
    a,
  );
}

List<ARGBColor> shade(
  ARGBColor seed,
  int length, {
  ShadeAlignment alignment = ShadeAlignment.start,
  double max = 1.0,
}) {
  final result = <ARGBColor>[];
  final steps = length.abs();
  final reverse = length < 0;

  for (int i = 0; i < steps; i++) {
    double t = steps == 1 ? 0.0 : i / (steps - 1); // 0..1
    t *= max; // scale by max factor

    ARGBColor c;
    switch (alignment) {
      case ShadeAlignment.start:
        // seed at index 0
        c = reverse ? lightenColor(seed, t) : darkenColor(seed, t);
        break;
      case ShadeAlignment.end:
        // seed at last index
        c = reverse ? darkenColor(seed, 1 - t) : lightenColor(seed, 1 - t);
        break;
      case ShadeAlignment.center:
        // seed in middle
        double mid = (steps - 1) / 2.0;
        double dist = (i - mid).abs() / mid; // 0 at center, 1 at edges
        dist *= max;
        c = (i < mid)
            ? (reverse ? darkenColor(seed, dist) : lightenColor(seed, dist))
            : (reverse ? lightenColor(seed, dist) : darkenColor(seed, dist));
        break;
    }
    result.add(c);
  }
  return result;
}

List<ARGBColor> shadeBetween(
  ARGBColor c1,
  ARGBColor c2, {
  int length = 3,
  double max = 1.0,
}) {
  final steps = length.abs();
  final reverse = length < 0;
  final result = <ARGBColor>[];

  for (int i = 0; i < steps; i++) {
    double t = steps == 1 ? 0.0 : i / (steps - 1);
    if (reverse) t = 1 - t;
    t *= max; // scale blend
    result.add(colorMix(c1, c2, t));
  }
  return result;
}

String ansiColor(ARGBColor color, {int width = 1}) {
  return color == 0
    ? '\x1B[0m${'  ' * width}'
    : '\x1B[48;2;${getR(color)};${getG(color)};${getB(color)}m${'  ' * width}\x1B[0m';
}

String ansiShade(List<ARGBColor> colors, {int width = 1}) {
  StringBuffer buf = StringBuffer();

  for (final color in colors) {
    buf.write('\x1B[48;2;${getR(color)};${getG(color)};${getB(color)}m${'  ' * width}');
  }

  buf.write('\x1B[0m');
  return buf.toString();
}

String ansiColoredText(String text, int color) {
  return '\x1B[38;2;${getR(color)};${getG(color)};${getB(color)}m$text\x1B[0m';
}

num lerpNum(num a, num b, double t) {
  return a + (b - a) * t;
}

double lerpDouble(double a, double b, double t) {
  return a * (1.0 - t) + b * t;
}

int lerpInt(int a, int b, double t) {
  return (a + (b - a) * t).round();
}