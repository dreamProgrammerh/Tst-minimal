# TSTM -- Theme Style Template (Minimal)

## Overview

**TSTM (Theme Style Template)** is a minimal, expression-based configuration language designed for **programmatic theming**.

TSTM allows defining named values using:

* arithmetic and bitwise expressions
* numeric and color literals
* function calls
* variable references
* logical, comparison, and conditional operators

The language prioritizes a **small, deterministic core** with clear runtime behavior.

---

## Program Structure

A TSTM source file represents a **program**.

A program is a **list of named declarations**, evaluated in order.

Each declaration:

* has a **name**
* has an **expression**
* produces a **runtime value**
* is evaluated **once**
* is cached after evaluation

### Conceptual AST Model

Although parsing may be performed line-by-line, the logical model is:

```
Program
 ├─ Decl(name, Expr)
 ├─ Decl(name, Expr)
 ├─ Decl(name, Expr)
 └─ ...
```

Key point:

> A TSTM program is a **list of AST nodes**, not a single tree and not independent ASTs per line.

Each declaration owns its own **expression tree**, and the program is an **ordered AST list**.

---

## Syntax

### Declaration

```tstm
name: expression
```

Rules:

* `name` must be a valid identifier
* declarations are evaluated top-to-bottom
* a name must be declared **before it is referenced**

Example:

```tstm
padding: 10 + 2 * 3
```

---

## Comments

### Line Comment

```
// comment until end of line
```

### Block Comment

```
/* multi-line
   comment */
```

Comments are ignored by the lexer and do not produce AST nodes.

---

## Values and Types

TSTM has **runtime types only**. There is no static type system.

### Runtime Types (Current)

| Type      | Description                |
| --------- | -------------------------- |
| `int32`   | 32-bit signed integer      |
| `float32` | 32-bit IEEE floating point |

> These are the **only runtime value types** at the moment.

---

## Boolean Semantics

TSTM does **not** have a boolean type.

Truthiness rules:

* `0` → false
* any non-zero value → true

All logical and comparison operations produce an `int32` result (`0` or `1`).

---

## Numeric Literals

TSTM supports multiple **numeric literal forms**, but **all numeric values are reduced at runtime** to either `int32` or `float32`.

### Integer Literals

Basic decimal integers:

```
0
42
-7
```

### Floating-Point Literals

A number is considered floating-point if it contains a decimal point.

Valid forms:

```
3.14
1.0
.5
10.0
```

All floating-point literals produce a `float32` at runtime.

---

### Numeric Separators

The underscore `_` may be used as a **visual separator** in numeric literals.

Rules:

* separators are ignored by the lexer
* they may appear between digits
* they do not affect the numeric value

Examples:

```
1_000
10_000_000
3.141_592
```

---

### Numeric Bases (Lexical Support)

The lexer may recognize different base prefixes (implementation-defined), but:

> **At runtime, all integer values are stored as `int32`.**

Examples of commonly supported forms:

```
0b1010      // binary
0o755       // octal
0xFF        // hexadecimal
```

Regardless of literal form:

* binary, octal, hex → `int32`
* overflow behavior is implementation-defined

---

### Type Normalization Rule

| Literal Form | Runtime Type |
| ------------ | ------------ |
| integer      | `int32`      |
| float        | `float32`    |

There are **no other numeric runtime types**, even if additional literal forms exist in the lexer.

---

## Color Literals

Any token starting with `#` is a **color literal**.

Color literals always produce an `int32` in **ARGB format** (`AARRGGBB`).

### Supported Forms

| Literal     | Meaning      | Result Format |
| ----------- | ------------ | ------------- |
| `#f`        | grayscale    | `FFffffff`    |
| `#ff`       | alpha + gray | `AAffffff`    |
| `#rgb`      | RGB          | `FFrrggbb`    |
| `#rgba`     | RGBA         | `AArrggbb`    |
| `#rrggbb`   | RGB          | `FFrrggbb`    |
| `#rrggbbaa` | RGBA         | `AArrggbb`    |

Examples:

```
#a
#ff
#abc
#abcd
#112233
#11223344
```

---

## Variables

Variables are referenced using `$`.

```
$base
```

Rules:

* variables must be declared **before use**
* variables store **evaluated values**
* accessing a variable does **not** re-evaluate its expression

Example:

```
base: 10 + 2 * 3
result: $base + 1
```

---

## Built-in Functions

Functions use standard call syntax:

```
name(arg1, arg2, ...)
```

Functions are resolved via a **runtime registry**.

### Examples

#### rgb(r, g, b)

```
rgb(0, 255, 0)
```

Returns an ARGB `int32` with alpha = 255.

#### rgba(r, g, b, a)

```
rgba(255, 0, 0, 128)
```

Returns an ARGB `int32`.

---

## Operators

### Arithmetic Operators

| Operator | Description             |
| -------- | ----------------------- |
| `+`      | addition                |
| `-`      | subtraction             |
| `*`      | multiplication          |
| `/`      | division (float result) |
| `/%`     | integer division        |
| `%`      | modulo                  |
| `**`     | power                   |

---

### Bitwise Operators (int32 only)

| Operator | Description  |
| -------- | ------------ |
| `&`      | AND          |
| `\|`     | OR           |
| `^`      | XOR          |
| `~`      | NOT          |
| `<<`     | shift left   |
| `>>`     | shift right  |
| `<<<`    | rotate left  |
| `>>>`    | rotate right |

---

### Comparison Operators

All comparisons return `int32` (`0` or `1`).

| Operator | Meaning                        |
| -------- | ------------------------------ |
| `==`     | value equality                 |
| `!=`     | value inequality               |
| `===`    | strict equality (type + value) |
| `!==`    | strict inequality              |
| `<`      | less than                      |
| `>`      | greater than                   |
| `<=`     | less or equal                  |
| `>=`     | greater or equal               |
| `~=`     | approximate equality           |
| `!~=`    | approximate inequality         |

---

### Logical Operators

| Operator | Meaning     |
| -------- | ----------- |
| `!`      | logical NOT |
| `&&`     | logical AND |
| `\|\|`   | logical OR  |
| `^^`     | logical XOR |

---

### Coalescing and Guard Operators

| Operator | Semantics                               |
| -------- | --------------------------------------- |
| `??`     | if left is false (`0`), return right    |
| `!!`     | if right is true, return left; else `0` |

Examples:

```
a ?? b
x !! condition
```

---

## Ternary Operator

```
condition ? exprTrue : exprFalse
```

Rules:

* `0` → false
* non-zero → true

Example:

```
primary: darkMode ? $dark : $light
```

---

## Evaluation Rules

* expressions are parsed into AST trees
* the program is a **list of AST nodes**
* each declaration is evaluated once
* results are cached
* variable access is resolved through the evaluation context
* cycles produce runtime errors

---

## Example Program

```
base: 10 + 2 * 3
a: $base + 1
b: $base + 2
c: $a + $b

red: rgba(255, 0, 0, 255)
green: rgb(0, 255, 0)

enabled: 1
value: enabled ? 42 : 0
```

---

## **Summary**

* Program = **ordered list of AST nodes**
* Expressions are full trees
* Runtime types are minimal (`int32`, `float32`)
* Booleans are numeric
* Designed for clarity, predictability, and extensibility

---

## What “Minimal” Means in TST (Minimal)

The term **“Minimal”** in **TST (Minimal)** indicates that this language is a **reduced, core subset** of the full TST vision.

TST (Minimal) exists to provide:

* a **small and stable core**
* a **fast-to-implement prototype**
* a **production-usable subset** suitable for immediate integration

This version focuses exclusively on:

* expressions
* numeric and color values
* operators
* function calls
* named declarations

There are **no blocks, scopes, control flow, collections, or user-defined types** in the minimal version.

---

### Relationship to Full TST

The **full TST language** is envisioned as a **rich, graphical theming language** used to define and control the visual style of applications.

Its long-term goals include:

* expressive, readable syntax for designers and developers
* server-driven theming
* live updates without app redeployment
* complex theme logic (palettes, contexts, modes, states)

TST acts as the **“style layer” of an application**, designed to be:

* human-readable
* easy to modify
* safe to evaluate
* expressive enough for real-world UI needs

---

### Why a Minimal Version Exists

TST (Minimal) was created to:

* validate the language core quickly
* reduce implementation complexity
* avoid premature design commitments
* allow real-world usage while the full language evolves

The minimal version can be implemented in **days**, not months, while still preserving:

* the AST model
* runtime evaluation rules
* operator semantics
* forward compatibility with full TST

---

### Design Principle

> **TST (Minimal) is not a different language.**
> It is the **foundation layer** of TST.

Everything added later in full TST is expected to **build on this core**, not replace it.
