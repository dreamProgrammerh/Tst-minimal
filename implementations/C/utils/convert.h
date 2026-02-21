#pragma once

#include "short-types.h"

// ================================
// UTILITY FUNCTIONS
// ================================

static inline
bool _cvt_isDigit(const char c) {
    return c >= '0' && c <= '9';
}

static inline
bool _cvt_isHexDigit(const char c) {
    return (c >= '0' && c <= '9') ||
           (c >= 'a' && c <= 'f') ||
           (c >= 'A' && c <= 'F');
}

static inline
int _cvt_hexCharToInt(const char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return 10 + (c - 'a');
    if (c >= 'A' && c <= 'F') return 10 + (c - 'A');
    return -1;
}

// ================================
// HEX TO ARGB COLOR
// ================================

typedef u32 ArgbColor;

/**
 * Converts a hex integer to ARGB color format.
 * Supports various input formats:
 * - 0x0 to 0xF                 -> Single digit grayscale (expanded to 0xFFCCCCCC)
 * - 0x00 to 0xFF               -> Grayscale + Alpha (0xAACCCCCC)
 * - 0x000 to 0xFFF             -> 3-digit RGB (0xFFRRGGBB)
 * - 0x0000 to 0xFFFF           -> 4-digit RGBA (0xAARRGGBB)
 * - 0x000000 to 0xFFFFFF       -> 6-digit RRGGBB (0xFFRRGGBB)
 * - 0x00000000 to 0xFFFFFFFF   -> 8-digit RRGGBBAA (0xAARRGGBB)
 */
static inline
ArgbColor cvt_hexToColor(const u32 value) {
    // Single digit grayscale (0xC -> 0xFFCCCCCC)
    if (value <= 0xF) {
        const u32 c = value * 0x11;  // Expand 0xC to 0xCC
        return 0xFF000000 | (c << 16) | (c << 8) | c;
    }

    // Alpha + grayscale (0xCA -> 0xAACCCCCC)
    if (value <= 0xFF) {
        const u32 c = ((value >> 4) & 0xF) * 0x11;
        const u32 a = (value & 0xF) * 0x11;
        return (a << 24) | (c << 16) | (c << 8) | c;
    }

    // 3-digit RGB (0xRGB -> 0xFFRRGGBB)
    if (value <= 0xFFF) {
        const u32 r = ((value >> 8) & 0xF) * 0x11;
        const u32 g = ((value >> 4) & 0xF) * 0x11;
        const u32 b = (value & 0xF) * 0x11;
        return 0xFF000000 | (r << 16) | (g << 8) | b;
    }

    // 4-digit RGBA (0xRGBA -> 0xAARRGGBB)
    if (value <= 0xFFFF) {
        const u32 r = ((value >> 12) & 0xF) * 0x11;
        const u32 g = ((value >> 8) & 0xF) * 0x11;
        const u32 b = ((value >> 4) & 0xF) * 0x11;
        const u32 a = (value & 0xF) * 0x11;
        return (a << 24) | (r << 16) | (g << 8) | b;
    }

    // 6-digit RGB (0xRRGGBB -> 0xFFRRGGBB)
    if (value <= 0xFFFFFF) {
        return 0xFF000000 | value;
    }

    // 8-digit ARGB (0xRRGGBBAA -> 0xAARRGGBB)
    if (value <= 0xFFFFFFFF) {
        // Convert from RRGGBBAA to AARRGGBB
        const u32 rrggbb = value >> 8;
        const u32 aa = (value & 0xFF) << 24;
        return aa | rrggbb;
    }

    return 0;
}

/**
 * Converts a hex integer to ARGB color, assuming ARGB input format.
 * Supports various input formats:
 * - 0x0 to 0xF                 -> Single digit grayscale (expanded to 0xFFCCCCCC)
 * - 0x00 to 0xFF               -> Alpha + grayscale (0xAACCCCCC)
 * - 0x000 to 0xFFF             -> 3-digit RGB (0xFFRRGGBB)
 * - 0x0000 to 0xFFFF           -> 4-digit ARGB (0xAARRGGBB)
 * - 0x000000 to 0xFFFFFF       -> 6-digit RRGGBB (0xFFRRGGBB)
 * - 0x00000000 to 0xFFFFFFFF   -> 8-digit AARRGGBB (0xAARRGGBB)
 */
static inline
ArgbColor cvt_hexToColorARGB(const u32 value) {
    // Single digit grayscale (0xC -> 0xFFCCCCCC)
    if (value <= 0xF) {
        const u32 c = value * 0x11;  // Expand 0xC to 0xCC
        return 0xFF000000 | (c << 16) | (c << 8) | c;
    }

    // Alpha + grayscale (0xAC -> 0xAACCCCCC)
    if (value <= 0xFF) {
        const u32 a = ((value >> 4) & 0xF) * 0x11;
        const u32 c = (value & 0xF) * 0x11;
        return (a << 24) | (c << 16) | (c << 8) | c;
    }

    // 3-digit RGB (0xRGB -> 0xFFRRGGBB)
    if (value <= 0xFFF) {
        const u32 r = ((value >> 8) & 0xF) * 0x11;
        const u32 g = ((value >> 4) & 0xF) * 0x11;
        const u32 b = (value & 0xF) * 0x11;
        return 0xFF000000 | (r << 16) | (g << 8) | b;
    }

    // 4-digit RGBA (0xARGB -> 0xAARRGGBB)
    if (value <= 0xFFFF) {
        const u32 a = ((value >> 12) & 0xF) * 0x11;
        const u32 r = ((value >> 8) & 0xF) * 0x11;
        const u32 g = ((value >> 4) & 0xF) * 0x11;
        const u32 b = (value & 0xF) * 0x11;
        return (a << 24) | (r << 16) | (g << 8) | b;
    }

    // 6-digit RGB (0xRRGGBB -> 0xFFRRGGBB)
    if (value <= 0xFFFFFF) {
        return 0xFF000000 | value;
    }

    // For AARRGGBB format, 8-digit is already correct
    return value;
}

// ================================
// STRING TO ARGB COLOR
// ================================

/**
 * Parses a hex color string to ARGB color value.
 * Supports formats:
 * - "C"           -> 0xFFCCCCCC (single digit grayscale)
 * - "CA"          -> 0xAACCCCCC (alpha + grayscale)
 * - "RGB"         -> 0xFFRRGGBB (3-digit color)
 * - "RGBA"        -> 0xAARRGGBB (4-digit color with alpha)
 * - "RRGGBB"      -> 0xFFRRGGBB (6-digit color)
 * - "RRGGBBAA"    -> 0xAARRGGBB (8-digit color)
 *
 * Also supports optional "#" prefix and underscores as separators.
 * Returns 0 on error (since 0 is a valid color? Maybe use error flag)
 */
static inline
ArgbColor cvt_hexStrToColor(const char* str, const usize len, bool* success) {
    if (!str || len == 0) {
        if (success) *success = false;
        return 0;
    }

    // Skip optional '#' prefix
    usize i = str[0] == '#';

    // Skip underscores and spaces, collect valid hex digits
    char digits[16];  // Max 8 hex digits + null
    usize digit_count = 0;

    for (; i < len && digit_count < 16; i++) {
        const char c = str[i];
        if (c == '_') continue;  // Skip separators

        if (_cvt_hexCharToInt(c) != -1) {
            digits[digit_count++] = c;

        } else {
            // Invalid character
            if (success) *success = false;
            return 0;
        }
    }

    if (digit_count == 0) {
        if (success) *success = false;
        return 0;
    }

    // Process based on digit count
    char expanded[9] = {0};  // 8 digits + null
    ArgbColor result = 0;

    switch (digit_count) {
        case 1:  // C -> ffCCCCCC
            expanded[0] = 'f'; expanded[1] = 'f';
            expanded[2] = digits[0]; expanded[3] = digits[0];
            expanded[4] = digits[0]; expanded[5] = digits[0];
            expanded[6] = digits[0]; expanded[7] = digits[0];
            break;

        case 2:  // CA -> AACCCCCC
            expanded[0] = digits[1]; expanded[1] = digits[1];
            expanded[2] = digits[0]; expanded[3] = digits[0];
            expanded[4] = digits[0]; expanded[5] = digits[0];
            expanded[6] = digits[0]; expanded[7] = digits[0];
            break;

        case 3:  // RGB -> ffRRGGBB
            expanded[0] = 'f'; expanded[1] = 'f';
            expanded[2] = digits[0]; expanded[3] = digits[0];
            expanded[4] = digits[1]; expanded[5] = digits[1];
            expanded[6] = digits[2]; expanded[7] = digits[2];
            break;

        case 4:  // RGBA -> AARRGGBB
            expanded[0] = digits[3]; expanded[1] = digits[3];
            expanded[2] = digits[0]; expanded[3] = digits[0];
            expanded[4] = digits[1]; expanded[5] = digits[1];
            expanded[6] = digits[2]; expanded[7] = digits[2];
            break;

        case 6:  // RRGGBB -> ffRRGGBB
            expanded[0] = 'f'; expanded[1] = 'f';
            expanded[2] = digits[0]; expanded[3] = digits[1];
            expanded[4] = digits[2]; expanded[5] = digits[3];
            expanded[6] = digits[4]; expanded[7] = digits[5];
            break;

        case 8:  // RRGGBBAA -> already correct format
            expanded[0] = digits[6]; expanded[1] = digits[7];
            expanded[2] = digits[0]; expanded[3] = digits[1];
            expanded[4] = digits[2]; expanded[5] = digits[3];
            expanded[6] = digits[4]; expanded[7] = digits[5];
            break;

        default:
            if (success) *success = false;
            return 0;  // Invalid length
    }

    // Convert expanded hex string to integer
    for (int j = 0; j < 8; j++) {
        result = (result << 4) | _cvt_hexCharToInt(expanded[j]);
    }

    if (success) *success = true;
    return result;
}

/**
 * Parses a hex color string assuming ARGB input format, to ARGB color value.
 * Supports formats:
 * - "C"           -> 0xFFCCCCCC (single digit grayscale)
 * - "CA"          -> 0xAACCCCCC (alpha + grayscale)
 * - "RGB"         -> 0xFFRRGGBB (3-digit color)
 * - "ARGB"        -> 0xAARRGGBB (4-digit color with alpha)
 * - "RRGGBB"      -> 0xFFRRGGBB (6-digit color)
 * - "AARRGGBB"    -> 0xAARRGGBB (8-digit color)
 *
 * Also supports optional "#" prefix and underscores as separators.
 * Returns 0 on error (since 0 is a valid color? Maybe use error flag)
 */
static inline
ArgbColor cvt_hexStrToColorARGB(const char* str, const usize len, bool* success) {
    if (!str || len == 0) {
        if (success) *success = false;
        return 0;
    }

    // Skip optional '#' prefix
    usize i = str[0] == '#';

    // Skip underscores and spaces, collect valid hex digits
    char digits[16];  // Max 8 hex digits + null
    usize digit_count = 0;

    for (; i < len && digit_count < 16; i++) {
        const char c = str[i];
        if (c == '_') continue;  // Skip separators

        if (_cvt_hexCharToInt(c) != -1) {
            digits[digit_count++] = c;

        } else {
            // Invalid character
            if (success) *success = false;
            return 0;
        }
    }

    if (digit_count == 0) {
        if (success) *success = false;
        return 0;
    }

    // Process based on digit count
    char expanded[9] = {0};  // 8 digits + null
    ArgbColor result = 0;

    switch (digit_count) {
        case 1:  // C -> ffCCCCCC
            expanded[0] = 'f'; expanded[1] = 'f';
            expanded[2] = digits[0]; expanded[3] = digits[0];
            expanded[4] = digits[0]; expanded[5] = digits[0];
            expanded[6] = digits[0]; expanded[7] = digits[0];
            break;

        case 2:  // AC -> AACCCCCC
            expanded[0] = digits[0]; expanded[1] = digits[0];
            expanded[2] = digits[1]; expanded[3] = digits[1];
            expanded[4] = digits[1]; expanded[5] = digits[1];
            expanded[6] = digits[1]; expanded[7] = digits[1];
            break;

        case 3:  // RGB -> ffRRGGBB
            expanded[0] = 'f'; expanded[1] = 'f';
            expanded[2] = digits[0]; expanded[3] = digits[0];
            expanded[4] = digits[1]; expanded[5] = digits[1];
            expanded[6] = digits[2]; expanded[7] = digits[2];
            break;

        case 4:  // ARGB -> AARRGGBB
            expanded[0] = digits[0]; expanded[1] = digits[0];
            expanded[2] = digits[1]; expanded[3] = digits[1];
            expanded[4] = digits[2]; expanded[5] = digits[2];
            expanded[6] = digits[3]; expanded[7] = digits[3];
            break;

        case 6:  // RRGGBB -> ffRRGGBB
            expanded[0] = 'f'; expanded[1] = 'f';
            expanded[2] = digits[0]; expanded[3] = digits[1];
            expanded[4] = digits[2]; expanded[5] = digits[3];
            expanded[6] = digits[4]; expanded[7] = digits[5];
            break;

        case 8:  // RRGGBBAA -> already correct format
            expanded[0] = digits[0]; expanded[1] = digits[1];
            expanded[2] = digits[2]; expanded[3] = digits[3];
            expanded[4] = digits[4]; expanded[5] = digits[5];
            expanded[6] = digits[6]; expanded[7] = digits[7];
            break;

        default:
            if (success) *success = false;
            return 0;  // Invalid length
    }

    // Convert expanded hex string to integer
    for (int j = 0; j < 8; j++) {
        result = (result << 4) | _cvt_hexCharToInt(expanded[j]);
    }

    if (success) *success = true;
    return result;
}

// ================================
// INTEGER CONVERSIONS
// ================================

static inline
i32 cvt_binToInt(const char* str, const usize len) {
    if (!str || len == 0) return 0;

    i32 result = 0;
    bool negative = false;
    usize i = 0;

    // Handle sign
    if (str[0] == '-') {
        negative = true;
        i++;
    } else if (str[0] == '+') {
        i++;
    }

    // Skip "0b" prefix if present
    if (len >= 2 && str[i] == '0' &&
        (str[i+1] == 'b' || str[i+1] == 'B')) {
        i += 2;
    }

    for (; i < len; i++) {
        const char c = str[i];
        if (c == '_') continue;

        if (c != '0' && c!= '1') break;
        result = result << 1 | (c - '0');
    }

    return negative ? -result : result;
}

static inline
i32 cvt_octToInt(const char* str, const usize len) {
    if (!str || len == 0) return 0;

    i32 result = 0;
    bool negative = false;
    usize i = 0;

    // Handle sign
    if (str[0] == '-') {
        negative = true;
        i++;
    } else if (str[0] == '+') {
        i++;
    }

    // Skip "0o" prefix if present
    if (len >= 2 && str[i] == '0' &&
        (str[i+1] == 'o' || str[i+1] == 'O')) {
        i += 2;
    }

    for (; i < len; i++) {
        const char c = str[i];
        if (c == '_') continue;

        if (!('0' <= c && c <= '7')) break;
        result = result << 3 | (c - '0');
    }

    return negative ? -result : result;
}

/**
 * Parses a mask string with O/I/R notation following these rules:
 * - 'O' or 'o' : put 0, length determined by next digits or repeated O's
 * - 'I' or 'i' : put 1, length determined by next digits or repeated I's
 * - 'R' or 'r' : repeat everything before, length determined by next digits or repeated R's
 *
 * Length rules:
 * - If next char is digit: read all digits for length
 * - If next action is same: count consecutive same actions for length
 * - Single action without length spec → length = 1
 *
 * Examples:
 * "0mIIOOr"   → 0b1100
 * "0mIIOOrr"  → 0b11001100
 * "0mI2OOr2"  → 0b11001100 (same as previous)
 */
static inline
u32 cvt_maskToInt(const char* str, const usize len) { // TODO: need testing
    if (!str || len == 0) return 0;

    u64 value = 0;
    usize bits = 0;
    bool overflow = false;

    // Skip "0m" or "0M" prefix if present
    usize i = 0;
    if (len >= 2 && str[0] == '0' &&
        (str[1] == 'm' || str[1] == 'M')) {
        i = 2;
    }

    // Store the pattern before first R for repeat operations
    uint64_t pattern_before_r = 0;
    usize bits_before_r = 0;
    bool has_pattern = false;

    while (i < len && !overflow) {
        const char current_action = str[i];

        // Check if it's a valid action
        if (current_action != 'O' && current_action != 'o' &&
            current_action != 'I' && current_action != 'i' &&
            current_action != 'R' && current_action != 'r') {
            i++;
            continue;
        }

        // Determine length
        usize length = 0;

        if (i + 1 >= len) {
            // Last character, no lookahead possible
            length = 1;
            i++;
        } else {
            // Look ahead to see what's next
            const char next = str[i + 1];

            if ('0' <= next && next <= '9') { // Case 1: Next char is digit - read all digits
                i++; // Move to first digit

                for (; i < len && '0' <= str[i] && str[i] <= '9'; i++) {
                    length = length * 10 + (str[i] - '0');
                }

                // 'i' is now at next action or end
            } else { // Case 2: Check for repeated same action

                if ((next | 32) != (current_action | 32)) {
                    // Different action, and no digits -> length = 1
                    length = 1;
                    i++; // Move past current action

                } else {
                    // Count consecutive same actions
                    length = 1;
                    i+=2; // Move to next action

                    for (; i < len && (str[i] | 32) == (current_action | 32); i++) {
                        length++;
                    }

                    // 'i' is now at next different action or end
                }
            }
        }

        // Now execute the action with determined length
        switch (current_action) {
            case 'o': case 'O': {
                // Put 'length' zeros
                if (bits + length > 64) {
                    overflow = true;
                    break;
                }

                for (usize j = 0; j < length; j++) {
                    value = (value << 1) | 0;
                }
                bits += length;

                // Update pattern for future R commands
                pattern_before_r = value;
                bits_before_r = bits;
                has_pattern = true;
                break;
            }

            case 'i': case 'I': {
                // Put 'length' ones
                if (bits + length > 64) {
                    overflow = true;
                    break;
                }

                for (usize j = 0; j < length; j++) {
                    value = (value << 1) | 1;
                }
                bits += length;

                // Update pattern for future R commands
                pattern_before_r = value;
                bits_before_r = bits;
                has_pattern = true;
                break;
            }

            case 'r': case 'R': {
                // Repeat everything before 'length' times
                if (!has_pattern) {
                    // No pattern to repeat, do nothing
                    break;
                }

                if (bits + (bits_before_r * (length - 1)) > 64) {
                    overflow = true;
                    break;
                }

                // Repeat the pattern (length-1) more times (since we already have it once)
                for (usize j = 1; j < length; j++) {
                    value = (value << bits_before_r) | pattern_before_r;
                    bits += bits_before_r;
                }
                break;
            }

            default:
                return 0;
        }
    }

    return value;
}

static inline
i32 cvt_hexToInt(const char* str, const usize len) {
    if (!str || len == 0) return 0;

    i32 result = 0;
    bool negative = false;
    usize i = 0;

    // Handle sign
    if (str[0] == '-') {
        negative = true;
        i++;
    } else if (str[0] == '+') {
        i++;
    }

    // Skip "0x" prefix if present
    if (len - i >= 2 && str[i] == '0' &&
        (str[i+1] == 'x' || str[i+1] == 'X')) {
        i += 2;
    }

    for (; i < len; i++) {
        const char c = str[i];
        if (c == '_') continue;

        if (!_cvt_isHexDigit(c)) break;
        result = result << 4 | _cvt_hexCharToInt(c);
    }

    return negative ? -result : result;
}

static inline
i32 cvt_decimalToInt(const char* str, const usize len) {
    if (!str || len == 0) return 0;

    i32 result = 0;
    bool negative = false;
    usize i = 0;

    // Handle sign
    if (str[0] == '-') {
        negative = true;
        i++;
    } else if (str[0] == '+') {
        i++;
    }

    for (; i < len; i++) {
        const char c = str[i];
        if (c == '_') continue;

        if (!_cvt_isDigit(c)) break;

        // Check for overflow
        if (result > (INT32_MAX / 10)) {
            // Handle overflow
            return negative ? INT32_MIN : INT32_MAX;
        }
        result = result * 10 + (c - '0');
    }

    return negative ? -result : result;
}

// ================================
// FLOAT CONVERSIONS
// ================================

static inline
f32 cvt_floatToFloat(const char* str, const usize len) {
    if (!str || len == 0) return 0.0f;

    f32 result = 0.0f;
    f32 sign = 1.0f;
    usize i = 0;

    // Handle sign
    if (str[0] == '-') {
        sign = -1.0f;
        i++;
    } else if (str[0] == '+') {
        i++;
    }

    // Parse integer part
    bool has_digits = false;
    while (i < len) {
        const char c = str[i];
        if (c == '_') {
            i++;
            continue;
        }

        if (c == '.') {
            i++;
            break;
        }

        if (!_cvt_isDigit(c)) break;
        has_digits = true;
        result = result * 10.0f + (f32)(c - '0');
        i++;
    }

    // Parse fractional part
    if (i < len && str[i-1] == '.') {
        f32 fraction = 0.0f;
        f32 divisor = 1.0f;

        for (; i < len; i++) {
            const char c = str[i];
            if (c == '_') continue;

            if (!_cvt_isDigit(c)) break;

            has_digits = true;
            fraction = fraction * 10.0f + (f32)(c - '0');
            divisor *= 10.0f;
        }

        result += fraction / divisor;
    }

    // If no digits were found, return 0
    if (!has_digits) return 0.0f;

    return sign * result;
}

static inline
f32 cvt_expToFloat(const char* str, const usize len) {
    if (!str || len == 0) return 0.0f;

    f32 mantissa = 0.0f;
    f32 sign = 1.0f;
    usize i = 0;

    // Handle overall sign
    if (str[0] == '-') {
        sign = -1.0f;
        i++;
    } else if (str[0] == '+') {
        i++;
    }

    // Parse mantissa (can be float)
    bool has_mantissa_digits = false;
    bool in_fraction = false;
    f32 fraction_multiplier = 1.0f;

    for (; i < len; i++) {
        const char c = str[i];
        if (c == '_') continue;

        // Move past 'e'
        if (c == 'e' || c == 'E') { i++; break;}

        if (c == '.') {
            in_fraction = true;
            continue;
        }

        if (!_cvt_isDigit(c)) return sign * mantissa;

        has_mantissa_digits = true;
        if (in_fraction) {
            fraction_multiplier *= 0.1f;
            mantissa = mantissa + (f32)(c - '0') * fraction_multiplier;
        } else {
            mantissa = mantissa * 10.0f + (f32)(c - '0');
        }
    }

    // If no mantissa digits, return 0
    if (!has_mantissa_digits) return 0.0f;

    // Parse exponent if present
    if (i < len) {
        i32 exponent = 0;
        i32 exp_sign = 1;

        // Handle exponent sign
        if (str[i] == '-') {
            exp_sign = -1;
            i++;
        } else if (str[i] == '+') {
            i++;
        }

        // Parse exponent digits
        bool has_exp_digits = false;
        for (; i < len; i++) {
            const char c = str[i];
            if (c == '_') continue;

            if (!_cvt_isDigit(c)) break;
            has_exp_digits = true;

            // Check for overflow
            if (exponent > (INT32_MAX / 10)) {
                // Exponent too large, handle gracefully
                exponent = INT32_MAX;
                break;
            }
            exponent = exponent * 10 + (c - '0');
        }

        // Apply exponent if we have digits
        if (has_exp_digits) {
            const i32 exp_value = exp_sign * exponent;

            // Apply 10^exp_value to mantissa
            if (exp_value > 0) {
                for (i32 e = 0; e < exp_value; e++) mantissa *= 10.0f;

            } else if (exp_value < 0) {
                for (i32 e = 0; e > exp_value; e--) mantissa *= 0.1f;
            }
        }
    }

    return sign * mantissa;
}
