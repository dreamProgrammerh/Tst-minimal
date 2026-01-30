import 'dart:math' as math;

typedef ArgbColor = int;
typedef RgbaColor = ({int r, int g, int b, int a});
typedef HsloColor = ({double h, double s, double l, double o});
typedef HsvoColor = ({double h, double s, double v, double o});
typedef CmykaColor = ({int c, int m, int y, int k, int a});

enum ShadeAlignment { start, center, end }

// Precomputed constants for speed
const rgbDistance   = 441.6729559300637;    // sqrt(3 * 255^2)
const rgbaDistance  = 510.0;                // sqrt(4 * 255^2)
const rgbManhattan  = 765;                  // 255 * 3
const radToDeg      = 57.29577951308232;    // 180 / pi
const degToRad      = 0.017453292519943295; // pi / 180
const _tau           = 6.283185307179586;    // 2 * pi
const _inverseByte   = 0.003921568627450;    // 1 / 255
const _hueToRad      = 1.0471975511966;      // pi / 3

// Hue rotation matrix constants (luminance-preserving)
const _lumR = 0.213;  // Red luminance weight
const _lumG = 0.715;  // Green luminance weight
const _lumB = 0.072;  // Blue luminance weight

// Fixed-point luminance weights for integer math
const _lumRInt = 76;   // 0.299 * 256
const _lumGInt = 150;  // 0.587 * 256
const _lumBInt = 29;   // 0.114 * 256

// Colors Variants - Creating colors from different color models
// ============================================================

@pragma('vm:prefer-inline')
ArgbColor rgba(int r, int g, int b, [int a = 255]) =>
    (a << 24) | (r << 16) | (g << 8) | b;

@pragma('vm:prefer-inline')
ArgbColor rgbo(int r, int g, int b, [double o = 1.00]) =>
    ((o.clamp(0, 1) * 255).round() << 24) | (r << 16) | (g << 8) | b;

ArgbColor hsl(double h, double s, double l, [double o = 1.00]) {
  // HSL to RGB conversion formula
  h = (h * radToDeg) % 360;
  s = s.clamp(0.0, 1.0);
  l = l.clamp(0.0, 1.0);

  final c = (1.0 - (2.0 * l - 1.0).abs()) * s; // Chroma
  final x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs());
  final m = l - c * 0.5; // Match lightness

  double r, g, b;
  
  // Sector selection based on hue angle
  if (h < 60.0) {
    r = c; g = x; b = 0.0;
  } else if (h < 120.0) {
    r = x; g = c; b = 0.0;
  } else if (h < 180.0) {
    r = 0.0; g = c; b = x;
  } else if (h < 240.0) {
    r = 0.0; g = x; b = c;
  } else if (h < 300.0) {
    r = x; g = 0.0; b = c;
  } else {
    r = c; g = 0.0; b = x;
  }

  return rgbo(
    ((r + m) * 255.0).round(),
    ((g + m) * 255.0).round(),
    ((b + m) * 255.0).round(),
    o,
  );
}

ArgbColor hsv(double h, double s, double v, [double o = 1.00]) {
  // HSV to RGB conversion (similar to HSL but different formula)
  h = (h * radToDeg) % 360;
  s = s.clamp(0.0, 1.0);
  v = v.clamp(0.0, 1.0);

  final c = v * s; // Chroma
  final x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs());
  final m = v - c; // Match value

  double r, g, b;
  
  // Sector selection based on hue angle
  if (h < 60.0) {
    r = c; g = x; b = 0.0;
  } else if (h < 120.0) {
    r = x; g = c; b = 0.0;
  } else if (h < 180.0) {
    r = 0.0; g = c; b = x;
  } else if (h < 240.0) {
    r = 0.0; g = x; b = c;
  } else if (h < 300.0) {
    r = x; g = 0.0; b = c;
  } else {
    r = c; g = 0.0; b = x;
  }

  return rgbo(
    ((r + m) * 255.0).round(),
    ((g + m) * 255.0).round(),
    ((b + m) * 255.0).round(),
    o,
  );
}

@pragma('vm:prefer-inline')
ArgbColor cmyk(int c, int m, int y, int k, [int a = 255]) {
  // CMYK to RGB: C,M,Y,K in range 0-100, returns ARGB
  final kf = k / 100.0;
  final rf = (1.0 - (c / 100.0)) * (1.0 - kf);
  final gf = (1.0 - (m / 100.0)) * (1.0 - kf);
  final bf = (1.0 - (y / 100.0)) * (1.0 - kf);
  
  return (a << 24) | 
         ((rf * 255.0).round() << 16) | 
         ((gf * 255.0).round() << 8) | 
         (bf * 255.0).round();
}

@pragma('vm:prefer-inline')
RgbaColor toRgba(ArgbColor argb) {
  // Convert ARGB integer to RGBA tuple
  return (
    a: (argb >> 24) & 0xFF,
    r: (argb >> 16) & 0xFF, 
    g: (argb >> 8) & 0xFF, 
    b: argb & 0xFF, 
  );
}

@pragma('vm:prefer-inline')
HsloColor toHslo(ArgbColor argb) {
  // Convert ARGB to HSL with opacity
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  
  final rf = r * _inverseByte;  // Normalize to 0-1
  final gf = g * _inverseByte;
  final bf = b * _inverseByte;
  
  final max = math.max(rf, math.max(gf, bf));
  final min = math.min(rf, math.min(gf, bf));
  final delta = max - min;
  
  // Calculate hue (0-2π radians)
  double h = 0.0;
  if (delta != 0.0) {
    if (max == rf) {
      h = (gf - bf) / delta % 6.0;
    } else if (max == gf) {
      h = (bf - rf) / delta + 2.0;
    } else {
      h = (rf - gf) / delta + 4.0;
    }
    h *= _hueToRad;
    if (h < 0.0) h += _tau;
  }
  
  // Calculate lightness and saturation
  final l = (max + min) * 0.5;
  final s = delta == 0.0 ? 0.0 : delta / (1.0 - (2.0 * l - 1.0).abs());
  
  return (h: h, s: s, l: l, o: a * _inverseByte);
}

@pragma('vm:prefer-inline')
HsvoColor toHsvo(ArgbColor argb) {
  // Convert ARGB to HSV with opacity
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  
  final rf = r * _inverseByte;
  final gf = g * _inverseByte;
  final bf = b * _inverseByte;
  
  final max = math.max(rf, math.max(gf, bf));
  final min = math.min(rf, math.min(gf, bf));
  final delta = max - min;
  
  // Calculate hue (0-2π radians)
  double h = 0.0;
  if (delta != 0.0) {
    if (max == rf) {
      h = (gf - bf) / delta % 6.0;
    } else if (max == gf) {
      h = (bf - rf) / delta + 2.0;
    } else {
      h = (rf - gf) / delta + 4.0;
    }
    h *= _hueToRad;
    if (h < 0.0) h += _tau;
  }
  
  // Calculate saturation and value
  final s = max == 0.0 ? 0.0 : delta / max;
  final v = max;
  
  return (h: h, s: s, v: v, o: a * _inverseByte);
}

@pragma('vm:prefer-inline')
CmykaColor toCmyka(ArgbColor argb) {
  // Convert ARGB to CMYK with alpha
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  
  final rf = r * _inverseByte;
  final gf = g * _inverseByte;
  final bf = b * _inverseByte;
  
  // Calculate black component (K)
  final black = 1.0 - math.max(rf, math.max(gf, bf));
  
  double cyan = 0.0;
  double magenta = 0.0;
  double yellow = 0.0;
  
  // Calculate C, M, Y if not pure black
  if (black < 1.0) {
    cyan = (1.0 - rf - black) / (1.0 - black);
    magenta = (1.0 - gf - black) / (1.0 - black);
    yellow = (1.0 - bf - black) / (1.0 - black);
  }
  
  // Return as percentages 0-100
  return (
    c: (cyan * 100).round(),
    m: (magenta * 100).round(),
    y: (yellow * 100).round(),
    k: (black * 100).round(),
    a: a,
  );
}

// Hex color conversions
// =====================

@pragma('vm:prefer-inline')
ArgbColor hex(int value) {
  // Convert hex integer to ARGB, supports multiple formats
  if (value <= 0xF) {
    // 0xC → 0xFFCCCCCC (single digit grayscale)
    final c = value * 0x11; // Expand 0xC to 0xCC
    return 0xFF000000 | (c << 16) | (c << 8) | c;
  }
  
  if (value <= 0xFF) {
    // 0xCA → 0xAACCCCCC (alpha + grayscale)
    final a = ((value >> 4) & 0xF) * 0x11;
    final c = (value & 0xF) * 0x11;
    return (a << 24) | (c << 16) | (c << 8) | c;
  }
  
  if (value <= 0xFFF) {
    // 0xRGB → 0xFFRRGGBB (3-digit color)
    final r = ((value >> 8) & 0xF) * 0x11;
    final g = ((value >> 4) & 0xF) * 0x11;
    final b = (value & 0xF) * 0x11;
    return 0xFF000000 | (r << 16) | (g << 8) | b;
  }
  
  if (value <= 0xFFFF) {
    // 0xRGBA → 0xAARRGGBB (4-digit color with alpha)
    final r = ((value >> 12) & 0xF) * 0x11;
    final g = ((value >> 8) & 0xF) * 0x11;
    final b = ((value >> 4) & 0xF) * 0x11;
    final a = (value & 0xF) * 0x11;
    return (a << 24) | (r << 16) | (g << 8) | b;
  }
  
  if (value <= 0xFFFFFF) {
    // 0xRRGGBB → 0xFFRRGGBB (6-digit color)
    return 0xFF000000 | value;
  }
  
  if (value <= 0xFFFFFFFF) {
    // 0xRRGGBBAA → ARGB (8-digit color with alpha)
    return value;
  }
  
  return 0;
}

@pragma('vm:prefer-inline')
ArgbColor? hexColor(String color) {
  // Parse hex string to ARGB, supports # prefix and various formats
  String hex = color.startsWith('#') ? color.substring(1) : color;
  if (hex.isEmpty) return null;
  
  // Expand shorthand formats to full 8-digit hex
  switch (hex.length) {
    case 1:
      // C → ffCCCCCC
      hex = 'ff$hex$hex$hex$hex$hex$hex';
      break;
    
    case 2:
      // CA → AAAAAAAA CCCCCCCC
      final a = hex[0];
      final c = hex[1];
      hex = '$a$a$c$c$c$c$c$c';
      break;
    
    case 3:
      // RGB → ffRRGGBB
      final r = hex[0];
      final g = hex[1];
      final b = hex[2];
      hex = 'ff$r$r$g$g$b$b';
      break;
    
    case 4:
      // RGBA → AARRGGBB
      final a = hex[0];
      final r = hex[1];
      final g = hex[2];
      final b = hex[3];
      hex = '$a$a$r$r$g$g$b$b';
      break;
    
    case 6:
      // RRGGBB → ffRRGGBB
      hex = 'ff$hex';
      break;
    
    case 8:
      // RRGGBBAA → already correct format
      break;
    
    default:
      return null; // Invalid length
  }
  
  // Parse hex string to integer
  return int.tryParse(hex, radix: 16);
}

// Color Properties - Extracting color components and metrics
// ==========================================================

// Component extraction - fastest possible

@pragma('vm:prefer-inline')
int getA(ArgbColor c) => (c >> 24) & 0xFF;

@pragma('vm:prefer-inline')
int getR(ArgbColor c) => (c >> 16) & 0xFF;

@pragma('vm:prefer-inline')
int getG(ArgbColor c) => (c >> 8) & 0xFF;

@pragma('vm:prefer-inline')
int getB(ArgbColor c) => c & 0xFF;

@pragma('vm:prefer-inline')
double getO(ArgbColor c) => ((c >> 24) & 0xFF) * _inverseByte; // 0-1 opacity

// HSL/HSV properties

@pragma('vm:prefer-inline')
double getHue(ArgbColor c) {
  final r = (c >> 16) & 0xFF;
  final g = (c >> 8) & 0xFF;
  final b = c & 0xFF;
  
  final rf = r * _inverseByte; // Normalize to 0-1
  final gf = g * _inverseByte;
  final bf = b * _inverseByte;
  
  final max = math.max(rf, math.max(gf, bf));
  final min = math.min(rf, math.min(gf, bf));
  final delta = max - min;
  
  if (delta == 0.0) return 0.0; // Achromatic (gray)
  
  double hue;
  // Determine which RGB component is max
  if (max == rf) {
    hue = (gf - bf) / delta % 6.0;
  } else if (max == gf) {
    hue = (bf - rf) / delta + 2.0;
  } else {
    hue = (rf - gf) / delta + 4.0;
  }
  
  // Directly convert the 0-6 range to 0-2π radians
  hue *= _hueToRad;
  
  // Normalize to [0, 2π)
  return hue < 0.0 ? hue + _tau : hue;
}

@pragma('vm:prefer-inline')
double getSaturation(ArgbColor c) {
  // HSL saturation: 0-1, 0 = gray, 1 = fully saturated
  final r = (c >> 16) & 0xFF;
  final g = (c >> 8) & 0xFF;
  final b = c & 0xFF;
  
  final rf = r * _inverseByte;
  final gf = g * _inverseByte;
  final bf = b * _inverseByte;
  
  final max = math.max(rf, math.max(gf, bf));
  final min = math.min(rf, math.min(gf, bf));
  final delta = max - min;
  final l = (max + min) * 0.5; // Lightness
  
  return delta == 0.0 ? 0.0 : delta / (1.0 - (2.0 * l - 1.0).abs());
}

@pragma('vm:prefer-inline')
double getBrightness(ArgbColor c) {
  // HSL lightness: 0-1, 0 = black, 1 = white
  final r = (c >> 16) & 0xFF;
  final g = (c >> 8) & 0xFF;
  final b = c & 0xFF;
  
  final rf = r * _inverseByte;
  final gf = g * _inverseByte;
  final bf = b * _inverseByte;
  
  return (math.max(rf, math.max(gf, bf)) + math.min(rf, math.min(gf, bf))) * 0.5;
}

@pragma('vm:prefer-inline')
double getValue(ArgbColor c) {
  // HSV value: 0-1, 0 = black, 1 = max brightness
  final r = (c >> 16) & 0xFF;
  final g = (c >> 8) & 0xFF;
  final b = c & 0xFF;
  
  return math.max(r, math.max(g, b)) * _inverseByte;
}

@pragma('vm:prefer-inline')
double getSaturationV(ArgbColor c) {
  // HSV saturation: 0-1, 0 = gray, 1 = fully saturated
  final r = (c >> 16) & 0xFF;
  final g = (c >> 8) & 0xFF;
  final b = c & 0xFF;
  
  final max = math.max(r, math.max(g, b));
  final min = math.min(r, math.min(g, b));
  final delta = max - min;
  
  return max == 0 ? 0.0 : delta / max;
}

// CMYK properties (0-100%)

@pragma('vm:prefer-inline')
int getC(ArgbColor c) {
  final r = getR(c);
  final g = getG(c);
  final b = getB(c);
  
  final rf = r * _inverseByte;
  final gf = g * _inverseByte;
  final bf = b * _inverseByte;
  
  final max = math.max(rf, math.max(gf, bf));
  final black = 1.0 - max;
  
  if (black == 1.0) return 0; // Pure black
  
  final cyan = (1.0 - rf - black) / (1.0 - black);
  return (cyan * 100).round();
}

@pragma('vm:prefer-inline')
int getM(ArgbColor c) {
  final r = getR(c);
  final g = getG(c);
  final b = getB(c);
  
  final rf = r * _inverseByte;
  final gf = g * _inverseByte;
  final bf = b * _inverseByte;
  
  final max = math.max(rf, math.max(gf, bf));
  final black = 1.0 - max;
  
  if (black == 1.0) return 0; // Pure black
  
  final magenta = (1.0 - gf - black) / (1.0 - black);
  return (magenta * 100).round();
}

@pragma('vm:prefer-inline')
int getY(ArgbColor c) {
  final r = getR(c);
  final g = getG(c);
  final b = getB(c);
  
  final rf = r * _inverseByte;
  final gf = g * _inverseByte;
  final bf = b * _inverseByte;
  
  final max = math.max(rf, math.max(gf, bf));
  final black = 1.0 - max;
  
  if (black == 1.0) return 0; // Pure black
  
  final yellow = (1.0 - bf - black) / (1.0 - black);
  return (yellow * 100).round();
}

@pragma('vm:prefer-inline')
int getK(ArgbColor c) {
  final r = getR(c);
  final g = getG(c);
  final b = getB(c);
  
  final rf = r * _inverseByte;
  final gf = g * _inverseByte;
  final bf = b * _inverseByte;
  
  final max = math.max(rf, math.max(gf, bf));
  final black = 1.0 - max;
  
  return (black * 100).round();
}

// Color temperature properties

@pragma('vm:prefer-inline')
double getTemperature(ArgbColor c) {
  // Perceptual temperature with green contribution
  // temperature: -100 (cool/blue) to +100 (warm/red)
  final r = getR(c);
  final g = getG(c);
  final b = getB(c);
  return (r * 0.6 - b * 0.8 - g * 0.2) * _inverseByte * 100.0;
}

// Color luminance/brightness perception

@pragma('vm:prefer-inline')
double getLuminance(ArgbColor c) {
  // WCAG 2.0 relative luminance formula for contrast ratio
  final r = getR(c) * _inverseByte;
  final g = getG(c) * _inverseByte;
  final b = getB(c) * _inverseByte;
  
  // Gamma correction for sRGB
  final rf = r <= 0.03928 ? r / 12.92 : math.pow((r + 0.055) / 1.055, 2.4).toDouble();
  final gf = g <= 0.03928 ? g / 12.92 : math.pow((g + 0.055) / 1.055, 2.4).toDouble();
  final bf = b <= 0.03928 ? b / 12.92 : math.pow((b + 0.055) / 1.055, 2.4).toDouble();
  
  return 0.2126 * rf + 0.7152 * gf + 0.0722 * bf; // Luminance weights
}

// Color distance metrics

@pragma('vm:prefer-inline')
int manhattanDistance(ArgbColor c1, ArgbColor c2) {
  // Sum of absolute differences (taxicab distance)
  final r1 = (c1 >> 16) & 0xFF;
  final g1 = (c1 >> 8) & 0xFF;
  final b1 = c1 & 0xFF;
  final r2 = (c2 >> 16) & 0xFF;
  final g2 = (c2 >> 8) & 0xFF;
  final b2 = c2 & 0xFF;
  
  return (r1 - r2).abs() + (g1 - g2).abs() + (b1 - b2).abs(); // Max = 765
}

@pragma('vm:prefer-inline')
double distance(ArgbColor c1, ArgbColor c2) {
  // Euclidean distance in RGB space
  final dr = ((c1 >> 16) & 0xFF) - ((c2 >> 16) & 0xFF);
  final dg = ((c1 >> 8) & 0xFF) - ((c2 >> 8) & 0xFF);
  final db = (c1 & 0xFF) - (c2 & 0xFF);
  
  return math.sqrt(dr * dr + dg * dg + db * db); // Max ≈ 441.67
}

@pragma('vm:prefer-inline')
double difference(ArgbColor c1, ArgbColor c2) => distance(c1, c2) / rgbDistance; // Normalized 0-1

// Color classification

@pragma('vm:prefer-inline')
bool isLight(ArgbColor c) {
  // Fast perceptual brightness check (human eye weighted)
  final r = (c >> 16) & 0xFF;
  final g = (c >> 8) & 0xFF;
  final b = c & 0xFF;
  return (r * 299 + g * 587 + b * 114) >= 128000; // 128 * 1000
}

@pragma('vm:prefer-inline')
bool isDark(ArgbColor c) => !isLight(c);

@pragma('vm:prefer-inline')
bool isGray(ArgbColor c) {
  // Check if RGB components are approximately equal (±5)
  final r = (c >> 16) & 0xFF;
  final g = (c >> 8) & 0xFF;
  final b = c & 0xFF;
  final diffRG = (r - g).abs();
  final diffRB = (r - b).abs();
  final diffGB = (g - b).abs();
  return diffRG <= 5 && diffRB <= 5 && diffGB <= 5;
}

@pragma('vm:prefer-inline')
bool isNeon(ArgbColor c) {
  // High saturation (>80%) and high brightness (>70%)
  final r = (c >> 16) & 0xFF;
  final g = (c >> 8) & 0xFF;
  final b = c & 0xFF;
  
  final max = math.max(r, math.max(g, b));
  if (max == 0) return false;
  
  final min = math.min(r, math.min(g, b));
  final saturation = (max - min) / max;
  final value = max * _inverseByte;
  
  return saturation > 0.8 && value > 0.7;
}

@pragma('vm:prefer-inline')
bool isPastel(ArgbColor c) {
  // High lightness (>70%) and low saturation (<40%)
  final r = (c >> 16) & 0xFF;
  final g = (c >> 8) & 0xFF;
  final b = c & 0xFF;
  
  final rf = r * _inverseByte;
  final gf = g * _inverseByte;
  final bf = b * _inverseByte;
  
  final max = math.max(rf, math.max(gf, bf));
  final min = math.min(rf, math.min(gf, bf));
  final l = (max + min) * 0.5;
  
  if (l < 0.7) return false; // Too dark for pastel
  
  final delta = max - min;
  final s = delta == 0.0 ? 0.0 : delta / (1.0 - (2.0 * l - 1.0).abs());
  
  return s <= 0.4;
}

@pragma('vm:prefer-inline')
bool isVibrant(ArgbColor c) {
  // Moderate to high saturation (>50%) and brightness (>50%)
  final r = (c >> 16) & 0xFF;
  final g = (c >> 8) & 0xFF;
  final b = c & 0xFF;
  
  final max = math.max(r, math.max(g, b));
  if (max == 0) return false;
  
  final min = math.min(r, math.min(g, b));
  final saturation = (max - min) / max;
  final value = max * _inverseByte;
  
  return saturation > 0.5 && value > 0.5;
}

@pragma('vm:prefer-inline')
bool isSimilar(ArgbColor c1, ArgbColor c2, [double threshold = 10.0]) {
  // Check if colors are visually similar (within threshold distance)
  return distance(c1, c2) < threshold;
}

// Color Manipulation - Transforming and adjusting colors
// =====================================================

// Basic adjustments

@pragma('vm:prefer-inline')
ArgbColor darken(ArgbColor color, double percent) {
  // Reduce brightness by percentage (0-1)
  final factor = (1.0 - percent.clamp(0.0, 1.0));
  final a = color & 0xFF000000;
  final r = (((color >> 16) & 0xFF) * factor).clamp(0, 255).round();
  final g = (((color >> 8) & 0xFF) * factor).clamp(0, 255).round();
  final b = ((color & 0xFF) * factor).clamp(0, 255).round();
  return a | (r << 16) | (g << 8) | b;
}

@pragma('vm:prefer-inline')
ArgbColor lighten(ArgbColor color, double percent) {
  // Increase brightness by percentage (0-1)
  final factor = percent.clamp(0.0, 1.0);
  final a = color & 0xFF000000;
  final r = ((color >> 16) & 0xFF);
  final g = ((color >> 8) & 0xFF);
  final b = (color & 0xFF);
  
  final nr = (r + (255 - r) * factor).clamp(0, 255).round();
  final ng = (g + (255 - g) * factor).clamp(0, 255).round();
  final nb = (b + (255 - b) * factor).clamp(0, 255).round();
  
  return a | (nr << 16) | (ng << 8) | nb;
}

@pragma('vm:prefer-inline')
ArgbColor brightness(ArgbColor color, double factor) {
  // Multiply all RGB components by factor (0-1)
  factor = factor.clamp(0.0, 1.0);
  final a = color & 0xFF000000;
  final r = (((color >> 16) & 0xFF) * factor).clamp(0, 255).round();
  final g = (((color >> 8) & 0xFF) * factor).clamp(0, 255).round();
  final b = ((color & 0xFF) * factor).clamp(0, 255).round();
  return a | (r << 16) | (g << 8) | b;
}

@pragma('vm:prefer-inline')
ArgbColor saturation(ArgbColor color, double factor) {
  // Adjust saturation: 0 = grayscale, 1 = original, >1 = oversaturated
  factor = factor.clamp(0.0, 1.0);
  final a = color & 0xFF000000;
  final r = (color >> 16) & 0xFF;
  final g = (color >> 8) & 0xFF;
  final b = color & 0xFF;
  
  // Calculate luminance (grayscale) using integer weights
  final luma = (_lumRInt * r + _lumGInt * g + _lumBInt * b + 128) >> 8;
  
  // Interpolate between grayscale and original color
  final nr = (luma + (r - luma) * factor).clamp(0, 255).round();
  final ng = (luma + (g - luma) * factor).clamp(0, 255).round();
  final nb = (luma + (b - luma) * factor).clamp(0, 255).round();
  
  return a | (nr << 16) | (ng << 8) | nb;
}

@pragma('vm:prefer-inline')
ArgbColor opacity(ArgbColor color, double percent) {
  // Set opacity directly (0-1)
  final a = (255 * percent.clamp(0.0, 1.0)).round();
  return (a << 24) | (color & 0x00FFFFFF);
}

// Color transformations

@pragma('vm:prefer-inline')
ArgbColor grayscale(ArgbColor color) {
  // Convert to grayscale using luminance-preserving weights
  final a = color & 0xFF000000;
  final r = (color >> 16) & 0xFF;
  final g = (color >> 8) & 0xFF;
  final b = color & 0xFF;
  final gray = (_lumRInt * r + _lumGInt * g + _lumBInt * b + 128) >> 8;
  return a | (gray << 16) | (gray << 8) | gray;
}

@pragma('vm:prefer-inline')
ArgbColor tint(ArgbColor color, int delta) {
  // Move all channels by delta value towards white 
  final a = color & 0xFF000000;
  int r = (color >> 16) & 0xFF;
  int g = (color >> 8) & 0xFF;
  int b = color & 0xFF;
  
  delta = delta.abs();
  r = (r + delta).clamp(0, 255);
  g = (g + delta).clamp(0, 255);
  b = (b + delta).clamp(0, 255);
  return a | (r << 16) | (g << 8) | b;
}

@pragma('vm:prefer-inline')
ArgbColor tone(ArgbColor color, int delta) { // Should this be named shade??
  // Move all channels by delta value towards black 
  final a = color & 0xFF000000;
  int r = (color >> 16) & 0xFF;
  int g = (color >> 8) & 0xFF;
  int b = color & 0xFF;
  
  delta = delta.abs();
  r = (r - delta).clamp(0, 255);
  g = (g - delta).clamp(0, 255);
  b = (b - delta).clamp(0, 255);
  return a | (r << 16) | (g << 8) | b;
}

@pragma('vm:prefer-inline')
ArgbColor shift(ArgbColor color, int position) {
  // Move all channels avg to position
  final a = color & 0xFF000000;
  int r = (color >> 16) & 0xFF;
  int g = (color >> 8) & 0xFF;
  int b = color & 0xFF;
  
  final delta = ((r + g + b) / 3 - position.abs()).round();
  r = (r + delta).clamp(0, 255);
  g = (g + delta).clamp(0, 255);
  b = (b + delta).clamp(0, 255);
  return a | (r << 16) | (g << 8) | b;
}

@pragma('vm:prefer-inline')
ArgbColor invert(ArgbColor color) {
  // Invert RGB components (photographic negative)
  final a = color & 0xFF000000;
  final r = 255 - ((color >> 16) & 0xFF);
  final g = 255 - ((color >> 8) & 0xFF);
  final b = 255 - (color & 0xFF);
  return a | (r << 16) | (g << 8) | b;
}

@pragma('vm:prefer-inline')
ArgbColor complement(ArgbColor color) => shiftHue(color, math.pi); // Complementary color

// Color blending and mixing

@pragma('vm:prefer-inline')
ArgbColor mix(ArgbColor c1, ArgbColor c2, double t) {
  // Linear interpolation between two colors (t = 0 → c1, t = 1 → c2)
  t = t.clamp(0.0, 1.0);
  final invT = 1.0 - t;
  
  final a = ((c1 >> 24) & 0xFF) * invT + ((c2 >> 24) & 0xFF) * t;
  final r = ((c1 >> 16) & 0xFF) * invT + ((c2 >> 16) & 0xFF) * t;
  final g = ((c1 >> 8) & 0xFF) * invT + ((c2 >> 8) & 0xFF) * t;
  final b = (c1 & 0xFF) * invT + (c2 & 0xFF) * t;
  
  return (a.round() << 24) | (r.round() << 16) | (g.round() << 8) | b.round();
}

@pragma('vm:prefer-inline')
ArgbColor blendScreen(ArgbColor color1, ArgbColor color2) {
  // Screen blend mode: 255 - ((255 - a) * (255 - b) / 255)
  final r1 = (color1 >> 16) & 0xFF;
  final g1 = (color1 >> 8) & 0xFF;
  final b1 = color1 & 0xFF;
  
  final r2 = (color2 >> 16) & 0xFF;
  final g2 = (color2 >> 8) & 0xFF;
  final b2 = color2 & 0xFF;
  
  final r = 255 - ((255 - r1) * (255 - r2) ~/ 255);
  final g = 255 - ((255 - g1) * (255 - g2) ~/ 255);
  final b = 255 - ((255 - b1) * (255 - b2) ~/ 255);
  
  final a = math.max((color1 >> 24) & 0xFF, (color2 >> 24) & 0xFF).toInt();
  
  return (a << 24) | (r << 16) | (g << 8) | b;
}

@pragma('vm:prefer-inline')
ArgbColor mixer(List<ArgbColor> colors, [List<double>? weights]) {
  // Weighted average of multiple colors
  if (colors.isEmpty) return 0;
  
  weights ??= List.filled(colors.length, 1.0);
  assert(weights.length == colors.length, 'weights.length must equal colors.length');
  
  double total = 0.0;
  for (final w in weights) total += w;
  if (total == 0.0) return 0;
  
  double a = 0.0, r = 0.0, g = 0.0, b = 0.0;
  for (int i = 0; i < colors.length; i++) {
    final w = weights[i];
    final color = colors[i];
    a += ((color >> 24) & 0xFF) * w;
    r += ((color >> 16) & 0xFF) * w;
    g += ((color >> 8) & 0xFF) * w;
    b += (color & 0xFF) * w;
  }
  
  return ((a / total).round() << 24) |
         ((r / total).round() << 16) |
         ((g / total).round() << 8) |
         (b / total).round();
}

// Hue manipulation

@pragma('vm:prefer-inline')
ArgbColor hue(ArgbColor color, double angle) {
  // Set absolute hue (0-2π radians) - uses optimized hue rotation
  return shiftHue(color, angle - getHue(color));
}

@pragma('vm:prefer-inline')
ArgbColor hueFast(ArgbColor color, double angle) {
  // Fast hue rotation using precomputed matrices (30° increments)
  const multiplier = 1 / (_tau / 12);
  angle = angle < 0 ? angle + _tau : angle;
  
  final index = ((angle * multiplier).round() % 12);
  final m = _hueMatrices[index];
  
  final a = color & 0xFF000000;
  final r = (color >> 16) & 0xFF;
  final g = (color >> 8) & 0xFF;
  final b = color & 0xFF;
  
  final nr = r * m[0] + g * m[1] + b * m[2];
  final ng = r * m[3] + g * m[4] + b * m[5];
  final nb = r * m[6] + g * m[7] + b * m[8];
  
  return a | 
    (nr.clamp(0, 255).round() << 16) | 
    (ng.clamp(0, 255).round() << 8) | 
    nb.clamp(0, 255).round();
}

// Precomputed hue rotation matrices for 30° increments
const _hueMatrices = [
  [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0],                          // 0°
  [0.866, -0.250, 0.433, 0.250, 0.966, -0.058, -0.433, 0.058, 0.899],     // 30°
  [0.500, -0.433, 0.750, 0.433, 0.866, -0.250, -0.750, 0.250, 0.966],     // 60°
  [0.0, -0.5, 0.866, 0.5, 0.866, -0.5, -0.866, 0.5, 0.866],               // 90°
  [-0.5, -0.433, 0.750, 0.433, 0.5, 0.433, -0.75, 0.433, 0.5],            // 120°
  [-0.866, -0.250, 0.433, 0.250, 0.0, 0.866, -0.433, 0.866, 0.250],       // 150°
  [-1.0, 0.0, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, -1.0],                       // 180°
  [-0.866, 0.250, -0.433, -0.250, -0.966, 0.058, 0.433, -0.058, -0.899],  // 210°
  [-0.5, 0.433, -0.75, -0.433, -0.866, 0.250, 0.75, -0.250, -0.966],      // 240°
  [0.0, 0.5, -0.866, -0.5, -0.866, 0.5, 0.866, -0.5, -0.866],             // 270°
  [0.5, 0.433, -0.75, -0.433, -0.5, -0.433, 0.75, -0.433, -0.5],          // 300°
  [0.866, 0.250, -0.433, -0.250, 0.0, -0.866, 0.433, -0.866, -0.250],     // 330°
];

@pragma('vm:prefer-inline')
ArgbColor shiftHue(ArgbColor color, double angle) {
  // Rotate hue while preserving luminance
  final rad = angle;
  final cosA = math.cos(rad);
  final sinA = math.sin(rad);
  
  final a = color & 0xFF000000;
  final r = (color >> 16) & 0xFF;
  final g = (color >> 8) & 0xFF;
  final b = color & 0xFF;
  
  // Hue rotation matrix (luminance-preserving)
  final m11 = cosA + (1.0 - cosA) * _lumR;
  final m12 = (1.0 - cosA) * _lumG - sinA * _lumG;
  final m13 = (1.0 - cosA) * _lumB + sinA * (1.0 - _lumB);
  
  final m21 = (1.0 - cosA) * _lumR + sinA * 0.143;
  final m22 = cosA + (1.0 - cosA) * _lumG;
  final m23 = (1.0 - cosA) * _lumB - sinA * 0.283;
  
  final m31 = (1.0 - cosA) * _lumR - sinA * (1.0 - _lumR);
  final m32 = (1.0 - cosA) * _lumG + sinA * _lumG;
  final m33 = cosA + (1.0 - cosA) * _lumB;
  
  final nr = r * m11 + g * m12 + b * m13;
  final ng = r * m21 + g * m22 + b * m23;
  final nb = r * m31 + g * m32 + b * m33;
  
  return a | 
    (nr.clamp(0, 255).round() << 16) | 
    (ng.clamp(0, 255).round() << 8) | 
    nb.clamp(0, 255).round();
}

// Color temperature adjustments

@pragma('vm:prefer-inline')
ArgbColor shiftTemperature(ArgbColor color, double temperature) {
  // Shift color temperature: -100 (cool/blue) to +100 (warm/red)
  final t = temperature.clamp(-100.0, 100.0) / 100.0;
  
  final a = color & 0xFF000000;
  int r = (color >> 16) & 0xFF;
  int g = (color >> 8) & 0xFF;
  int b = color & 0xFF;
  
  if (t > 0) {
    // Warm shift: increase red, decrease blue
    r = (r + (255 - r) * t).clamp(0, 255).round();
    b = (b - b * t).clamp(0, 255).round();
  } else if (t < 0) {
    // Cool shift: increase blue, decrease red
    final absT = -t;
    r = (r - r * absT).clamp(0, 255).round();
    b = (b + (255 - b) * absT).clamp(0, 255).round();
  }
  
  return a | (r << 16) | (g << 8) | b;
}

@pragma('vm:prefer-inline')
ArgbColor temperature(ArgbColor color, double temperature) {
  // Set absolute temperature: -100 (cool/blue) to +100 (warm/red)
  final t = temperature.clamp(-100.0, 100.0) / 100.0;
  
  final a = color & 0xFF000000;
  final r = (color >> 16) & 0xFF;
  final g = (color >> 8) & 0xFF;
  final b = color & 0xFF;
  
  // Calculate luminance for consistent brightness
  final luma = (_lumRInt * r + _lumGInt * g + _lumBInt * b + 128) >> 8;
  
  int nr, ng, nb;
  
  if (t >= 0) {
    // Warm: red = max, blue scaled by (1-t)
    nr = 255;
    nb = (255 * (1.0 - t)).clamp(0, 255).round();
  } else {
    // Cool: blue = max, red scaled by (1-|t|)
    final absT = -t;
    nr = (255 * (1.0 - absT)).clamp(0, 255).round();
    nb = 255;
  }
  
  // Adjust green to maintain perceived brightness
  ng = ((luma * 255 - _lumRInt * nr - _lumBInt * nb) / _lumGInt).clamp(0, 255).round();
  
  return a | (nr << 16) | (ng << 8) | nb;
}

// Special effects

@pragma('vm:prefer-inline')
ArgbColor neon(ArgbColor color) {
  // Boost to neon appearance: max saturation, slight brightness increase
  final b = math.min(1.0, getBrightness(color) * 1.2);
  return saturation(brightness(color, b), 1.0);
}

@pragma('vm:prefer-inline')
ArgbColor pastel(ArgbColor color) {
  // Convert to pastel: mix with white (70% original, 30% white)
  final a = color & 0xFF000000;
  final r = (color >> 16) & 0xFF;
  final g = (color >> 8) & 0xFF;
  final b = color & 0xFF;
  
  final nr = (r * 0.7 + 255 * 0.3).round();
  final ng = (g * 0.7 + 255 * 0.3).round();
  final nb = (b * 0.7 + 255 * 0.3).round();
  
  return a | (nr << 16) | (ng << 8) | nb;
}

@pragma('vm:prefer-inline')
ArgbColor pressa(ArgbColor color) {
  // Premultiply alpha: multiply RGB by alpha/255
  final a = (color >> 24) & 0xFF;
  final factor = a * _inverseByte;
  final r = (((color >> 16) & 0xFF) * factor).round();
  final g = (((color >> 8) & 0xFF) * factor).round();
  final b = ((color & 0xFF) * factor).round();
  return rgba(r, g, b, a);
}

@pragma('vm:prefer-inline')
ArgbColor contrast(ArgbColor color, double factor) {
  // Adjust contrast: factor > 1 increases, < 1 decreases
  final a = color & 0xFF000000;
  final f = (int c) => ((c - 128) * factor + 128).clamp(0, 255).round();
  
  final r = f((color >> 16) & 0xFF);
  final g = f((color >> 8) & 0xFF);
  final b = f(color & 0xFF);
  
  return a | (r << 16) | (g << 8) | b;
}

@pragma('vm:prefer-inline')
ArgbColor vibrance(ArgbColor color, double amount) {
  // Smart saturation: boosts less saturated colors more
  final s = getSaturation(color);
  final boost = amount / 100.0;
  final adjustment = (1.0 - (s - 0.5).abs() * 2.0) * boost;
  return saturation(color, (s + adjustment).clamp(0.0, 1.0));
}

@pragma('vm:prefer-inline')
ArgbColor glow(ArgbColor color, double intensity) {
  // Create glow effect by blending with brighter version
  intensity = intensity.clamp(0.0, 1.0);
  final hslo = toHslo(color);
  
  // Create glow color (brighter, slightly desaturated)
  final glowL = math.min(1.0, hslo.l + intensity * 0.3);
  final glowS = hslo.s * (1.0 - intensity * 0.2);
  
  final glowColor = hsl(hslo.h, glowS, glowL, hslo.o);
  
  // Screen blend for glow effect
  return blendScreen(color, glowColor);
}

// Combined adjustments

@pragma('vm:prefer-inline')
ArgbColor adjustHSL(ArgbColor color, double hueAngle, double satFactor, double brightFactor) {
  // Combined HSL adjustment in single operation
  final a = color & 0xFF000000;
  int r = (color >> 16) & 0xFF;
  int g = (color >> 8) & 0xFF;
  int b = color & 0xFF;
  
  // Brightness adjustment
  if (brightFactor != 1.0) {
    brightFactor = brightFactor.clamp(0.0, 1.0);
    r = (r * brightFactor).clamp(0, 255).round();
    g = (g * brightFactor).clamp(0, 255).round();
    b = (b * brightFactor).clamp(0, 255).round();
  }
  
  // Saturation adjustment
  if (satFactor != 1.0) {
    satFactor = satFactor.clamp(0.0, 1.0);
    final luma = (_lumRInt * r + _lumGInt * g + _lumBInt * b + 128) >> 8;
    r = (luma + (r - luma) * satFactor).clamp(0, 255).round();
    g = (luma + (g - luma) * satFactor).clamp(0, 255).round();
    b = (luma + (b - luma) * satFactor).clamp(0, 255).round();
  }
  
  // Hue rotation (matrix multiplication)
  if (hueAngle != 0.0) {
    final rad = hueAngle % _tau;
    final cosA = math.cos(rad);
    final sinA = math.sin(rad);
    
    final m11 = cosA + (1.0 - cosA) * _lumR;
    final m12 = (1.0 - cosA) * _lumG - sinA * _lumG;
    final m13 = (1.0 - cosA) * _lumB + sinA * (1.0 - _lumB);
    
    final m21 = (1.0 - cosA) * _lumR + sinA * 0.143;
    final m22 = cosA + (1.0 - cosA) * _lumG;
    final m23 = (1.0 - cosA) * _lumB - sinA * 0.283;
    
    final m31 = (1.0 - cosA) * _lumR - sinA * (1.0 - _lumR);
    final m32 = (1.0 - cosA) * _lumG + sinA * _lumG;
    final m33 = cosA + (1.0 - cosA) * _lumB;
    
    final nr = r * m11 + g * m12 + b * m13;
    final ng = r * m21 + g * m22 + b * m23;
    final nb = r * m31 + g * m32 + b * m33;
    
    r = nr.clamp(0, 255).round();
    g = ng.clamp(0, 255).round();
    b = nb.clamp(0, 255).round();
  }
  
  return a | (r << 16) | (g << 8) | b;
}

// Color Shading - Gradient and lerping colors
// =====================================================

List<ArgbColor> interpolate(
  ArgbColor seed,
  int length, {
  ShadeAlignment alignment = ShadeAlignment.start,
  double max = 1.0,
}) {
  final result = <ArgbColor>[];
  final steps = length.abs();
  final reverse = length < 0;

  for (int i = 0; i < steps; i++) {
    double t = steps == 1 ? 0.0 : i / (steps - 1); // 0..1
    t *= max; // scale by max factor

    ArgbColor c;
    switch (alignment) {
      case ShadeAlignment.start:
        // seed at index 0
        c = reverse ? lighten(seed, t) : darken(seed, t);
        break;
      case ShadeAlignment.end:
        // seed at last index
        c = reverse ? darken(seed, 1 - t) : lighten(seed, 1 - t);
        break;
      case ShadeAlignment.center:
        // seed in middle
        double mid = (steps - 1) / 2.0;
        double dist = (i - mid).abs() / mid; // 0 at center, 1 at edges
        dist *= max;
        c = (i < mid)
            ? (reverse ? darken(seed, dist) : lighten(seed, dist))
            : (reverse ? lighten(seed, dist) : darken(seed, dist));
        break;
    }
    result.add(c);
  }
  return result;
}

List<ArgbColor> interpolateBetween(
  ArgbColor c1,
  ArgbColor c2, {
  int length = 3,
  double max = 1.0,
}) {
  final steps = length.abs();
  final reverse = length < 0;
  final result = <ArgbColor>[];

  for (int i = 0; i < steps; i++) {
    double t = steps == 1 ? 0.0 : i / (steps - 1);
    if (reverse) t = 1 - t;
    t *= max; // scale blend
    result.add(mix(c1, c2, t));
  }
  return result;
}

// Terminal Coloring - ANSI Color and colored text
// =====================================================

String ansi(ArgbColor color, {int width = 1}) {
  return color == 0
    ? '\x1B[0m${'  ' * width}'
    : '\x1B[48;2;${getR(color)};${getG(color)};${getB(color)}m${'  ' * width}\x1B[0m';
}

String ansiInterpolate(List<ArgbColor> colors, {int width = 1}) {
  StringBuffer buf = StringBuffer();

  for (final color in colors) {
    buf.write('\x1B[48;2;${getR(color)};${getG(color)};${getB(color)}m${'  ' * width}');
  }

  buf.write('\x1B[0m');
  return buf.toString();
}

String ansiText(String text, int color) {
  return '\x1B[38;2;${getR(color)};${getG(color)};${getB(color)}m$text\x1B[0m';
}
