# TSTM -- Theme Style Template (Minimal)

**TSTM** is a small, expression-based theming format designed for **programmatic application themes**.

It allows you to define theme values (colors, sizes, spacing, flags, etc.) using a readable syntax with math, color literals, functions, and simple logic -- without introducing a full styling language or framework.

TSTM is meant to be **embedded directly inside applications** as a smarter alternative to static theme files.

---

## Why TSTM Exists

Most applications do not need a full styling language.

They need:

* readable theme files
* computed values
* color math
* simple conditions
* runtime evaluation
* easy updates without code changes

TSTM provides exactly this -- and nothing more.

It sits between **static formats** (JSON, YAML) and **full DSLs**, offering just enough logic to make themes expressive and maintainable.

---

## What “Minimal” Means

**Minimal** does not mean incomplete or experimental.

It means **intentionally limited**.

TSTM focuses only on:

* named declarations
* expressions
* numeric and color values
* operators
* function calls
* variable references

It deliberately avoids:

* blocks and scopes
* control flow statements
* complex data structures
* full language features

This keeps TSTM:

* easy to embed
* fast to implement
* safe to evaluate
* simple to understand and edit

TSTM will always remain minimal by design.

---

## Basic Example

```tst
base: 10 + 2 * 3
padding: $base + 4

primary: #3366ff
secondary: rgba(255, 128, 0, 255)

enabled: 1
opacity: enabled ? 1.0 : 0.5
```

Each declaration is evaluated once and cached.
Variables must be defined before use.

---

## Designed For

* application theming
* server-driven theme values
* runtime theme evaluation
* cross-platform apps
* lightweight engines

TSTM is **not a full styling language** -- it is a **smart theme format**.

---

## Philosophy

> Small core \
> Clear semantics \
> Predictable behavior \
> Easy to embed \
> Easy to extend

If you need more?, full **TST** can build on the same concepts --
but TSTM stands on its own.
