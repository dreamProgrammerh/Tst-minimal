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
    return 0;
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
