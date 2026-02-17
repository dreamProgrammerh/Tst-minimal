#pragma once

// =============================================
// Operating System
// =============================================

// First, define all OS detection macros with 1 or 0
#if defined(_WIN32) || defined(_WIN64) || defined(__WIN32__) || defined(__TOS_WIN__) || defined(__WINDOWS__)
#   define OS_WINDOWS 1
#   if defined(_WIN64) || defined(__WIN64__)
#       define OS_WINDOWS_64 1
#       define OS_WINDOWS_32 0
#   else
#       define OS_WINDOWS_64 0
#       define OS_WINDOWS_32 1
#   endif
#else
#   define OS_WINDOWS 0
#endif

// macOS detection (Darwin kernel)
#if defined(__APPLE__) || defined(__MACH__)
#   include <TargetConditionals.h>
#   if TARGET_OS_MAC == 1
#       define OS_MACOS 1
#   else
#       define OS_MACOS 0
#   endif
#   if TARGET_OS_IPHONE == 1
#       define OS_IOS 1
#   else
#       define OS_IOS 0
#   endif
#   if TARGET_OS_TV == 1
#       define OS_TVOS 1
#   else
#       define OS_TVOS 0
#   endif
#   if TARGET_OS_WATCH == 1
#       define OS_WATCHOS 1
#   else
#       define OS_WATCHOS 0
#   endif
#   define OS_DARWIN 1
#else
#   define OS_MACOS 0
#   define OS_IOS 0
#   define OS_TVOS 0
#   define OS_WATCHOS 0
#   define OS_DARWIN 0
#endif

// Linux detection
#if defined(__linux__) || defined(__linux) || defined(linux) || defined(__gnu_linux__)
#   define OS_LINUX 1
#   if defined(__ANDROID__) || defined(ANDROID)
#       define OS_ANDROID 1
#   else
#       define OS_ANDROID 0
#   endif
#else
#   define OS_LINUX 0
#   define OS_ANDROID 0
#endif

// BSD family
#if defined(__FreeBSD__) || defined(__FreeBSD_kernel__)
#   define OS_FREEBSD 1
#   define OS_BSD 1
#else
#   define OS_FREEBSD 0
#endif

#if defined(__NetBSD__)
#   define OS_NETBSD 1
#   define OS_BSD 1
#else
#   define OS_NETBSD 0
#endif

#if defined(__OpenBSD__)
#   define OS_OPENBSD 1
#   define OS_BSD 1
#else
#   define OS_OPENBSD 0
#endif

#if defined(__DragonFly__)
#   define OS_DRAGONFLY 1
#   define OS_BSD 1
#else
#   define OS_DRAGONFLY 0
#endif

// Set OS_BSD to 0 if no BSD variant was detected
#ifndef OS_BSD
#   define OS_BSD 0
#endif

// Other Unix-like systems
#if defined(__unix__) || defined(__unix) || defined(unix) || defined(__CYGWIN__) || defined(__CYGWIN32__) || defined(__MINGW32__) || defined(__MINGW64__)
#   define OS_UNIX 1
#else
#   define OS_UNIX 0
#endif

// Cygwin/Mingw specific
#if defined(__CYGWIN__) || defined(__CYGWIN32__)
#   define OS_CYGWIN 1
#else
#   define OS_CYGWIN 0
#endif

#if defined(__MINGW32__) || defined(__MINGW64__)
#   define OS_MINGW 1
#else
#   define OS_MINGW 0
#endif

// Haiku
#if defined(__HAIKU__)
#   define OS_HAIKU 1
#else
#   define OS_HAIKU 0
#endif

// Solaris/Illumos
#if defined(__sun) || defined(sun)
#   define OS_SOLARIS 1
#   if defined(__SVR4) || defined(__svr4__)
#       define OS_SOLARIS_SVR4 1
#   else
#       define OS_SOLARIS_SVR4 0
#   endif
#else
#   define OS_SOLARIS 0
#   define OS_SOLARIS_SVR4 0
#endif

// HP-UX
#if defined(__hpux) || defined(__hpux__)
#   define OS_HPUX 1
#else
#   define OS_HPUX 0
#endif

// AIX
#if defined(_AIX) || defined(__AIX__) || defined(__aix__)
#   define OS_AIX 1
#else
#   define OS_AIX 0
#endif

// IRIX
#if defined(sgi) || defined(__sgi)
#   define OS_IRIX 1
#else
#   define OS_IRIX 0
#endif

// OS/2
#if defined(__OS2__) || defined(__TOS_OS2__)
#   define OS_OS2 1
#else
#   define OS_OS2 0
#endif

// Convenient helper macros (these work anywhere, not just in preprocessor)
#define OS_isWINDOWS   (OS_WINDOWS)
#define OS_isWINDOWS64 (OS_WINDOWS_64)
#define OS_isWINDOWS32 (OS_WINDOWS_32)
#define OS_isMACOS     (OS_MACOS)
#define OS_isIOS       (OS_IOS)
#define OS_isTVOS      (OS_TVOS)
#define OS_isWATCHOS   (OS_WATCHOS)
#define OS_isAPPLE     (OS_DARWIN)  // Any Apple platform
#define OS_isLINUX     (OS_LINUX && !OS_ANDROID)
#define OS_isANDROID   (OS_ANDROID)
#define OS_isBSD       (OS_BSD)
#define OS_isFREEBSD   (OS_FREEBSD)
#define OS_isNETBSD    (OS_NETBSD)
#define OS_isOPENBSD   (OS_OPENBSD)
#define OS_isDRAGONFLY (OS_DRAGONFLY)
#define OS_isCYGWIN    (OS_CYGWIN)
#define OS_isMINGW     (OS_MINGW)
#define OS_isHAIKU     (OS_HAIKU)
#define OS_isSOLARIS   (OS_SOLARIS)
#define OS_isHPUX      (OS_HPUX)
#define OS_isAIX       (OS_AIX)
#define OS_isIRIX      (OS_IRIX)
#define OS_isOS2       (OS_OS2)
#define OS_isUNIX      (OS_UNIX || OS_LINUX || OS_BSD || OS_MACOS || OS_SOLARIS || OS_HPUX || OS_AIX || OS_IRIX)

// Check for supported platforms
#if !OS_isWINDOWS && !OS_isAPPLE && !OS_isLINUX && !OS_isBSD && !OS_isANDROID
#   if OS_isUNIX
#       pragma message "Warning: Building for unknown Unix-like system - proceed with caution"
#   else
#       error "Unsupported or unknown operating system"
#   endif
#endif

// Platform-specific feature macros
#if OS_isWINDOWS
#   define OS_PATH_SEPARATOR '\\'
#   define OS_PATH_SEPARATOR_STR "\\"
#   define OS_NEWLINE "\r\n"
#elif OS_isAPPLE || OS_isLINUX || OS_isUNIX
#   define OS_PATH_SEPARATOR '/'
#   define OS_PATH_SEPARATOR_STR "/"
#   define OS_NEWLINE "\n"
#endif

// Endianness detection (common across platforms)
#if defined(__BYTE_ORDER__)
#   if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
#       define OS_LITTLE_ENDIAN 1
#       define OS_BIG_ENDIAN 0
#   elif __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#       define OS_LITTLE_ENDIAN 0
#       define OS_BIG_ENDIAN 1
#   endif
#elif defined(__BIG_ENDIAN__) || defined(_BIG_ENDIAN) || defined(__ARMEB__) || defined(__THUMBEB__) || defined(__AARCH64EB__) || defined(_MIPSEB)
#   define OS_LITTLE_ENDIAN 0
#   define OS_BIG_ENDIAN 1
#elif defined(__LITTLE_ENDIAN__) || defined(_LITTLE_ENDIAN) || defined(__ARMEL__) || defined(__THUMBEL__) || defined(__AARCH64EL__) || defined(_MIPSEL) || defined(__BYTE_ORDER) && (__BYTE_ORDER == __LITTLE_ENDIAN)
#   define OS_LITTLE_ENDIAN 1
#   define OS_BIG_ENDIAN 0
#else
#   pragma message "Warning: Unable to detect endianness - assuming little-endian"
#   define OS_LITTLE_ENDIAN 1
#   define OS_BIG_ENDIAN 0
#endif

// =============================================
// Architecture
// =============================================
// First, define all architecture macros with explicit 1/0 values
// Start with defaults (all 0)
#define ARCH_X86_64 0
#define ARCH_X86_32 0
#define ARCH_ARM64 0
#define ARCH_ARM32 0
#define ARCH_RISCV64 0
#define ARCH_RISCV32 0
#define ARCH_LOONGARCH64 0
#define ARCH_MIPS64 0
#define ARCH_MIPS32 0
#define ARCH_PPC64 0
#define ARCH_PPC32 0
#define ARCH_S390X 0
#define ARCH_S390 0
#define ARCH_SPARC64 0
#define ARCH_SPARC32 0
#define ARCH_ALPHA 0
#define ARCH_HPPA 0
#define ARCH_M68K 0
#define ARCH_IA64 0

#define ARCH_64BIT 0
#define ARCH_32BIT 0

#define ARCH_FAMILY_X86 0
#define ARCH_FAMILY_ARM 0
#define ARCH_FAMILY_RISCV 0
#define ARCH_FAMILY_LOONGARCH 0
#define ARCH_FAMILY_MIPS 0
#define ARCH_FAMILY_PPC 0
#define ARCH_FAMILY_S390 0
#define ARCH_FAMILY_SPARC 0
#define ARCH_FAMILY_ALPHA 0
#define ARCH_FAMILY_HPPA 0
#define ARCH_FAMILY_M68K 0
#define ARCH_FAMILY_IA64 0

// Architecture capability macros (default to 0)
#define ARCH_HAS_MMX 0
#define ARCH_HAS_SSE 0
#define ARCH_HAS_SSE2 0
#define ARCH_HAS_SSE3 0
#define ARCH_HAS_SSSE3 0
#define ARCH_HAS_SSE4_1 0
#define ARCH_HAS_SSE4_2 0
#define ARCH_HAS_NEON 0
#define ARCH_HAS_AES 0
#define ARCH_HAS_CRC32 0
#define ARCH_HAS_VECTOR 0
#define ARCH_HAS_BITMANIP 0

// Now detect the actual architecture and override the defaults
#if defined(__x86_64__) || defined(_M_X64) || defined(__amd64__)
#   undef ARCH_X86_64
#   undef ARCH_64BIT
#   undef ARCH_FAMILY_X86
#   define ARCH_X86_64 1
#   define ARCH_64BIT 1
#   define ARCH_FAMILY_X86 1

#   undef ARCH_HAS_SSE
#   undef ARCH_HAS_SSE2
#   undef ARCH_HAS_SSE3
#   undef ARCH_HAS_SSSE3
#   undef ARCH_HAS_SSE4_1
#   undef ARCH_HAS_SSE4_2
#   define ARCH_HAS_SSE 1
#   define ARCH_HAS_SSE2 1
#   define ARCH_HAS_SSE3 1
#   define ARCH_HAS_SSSE3 1
#   define ARCH_HAS_SSE4_1 1
#   define ARCH_HAS_SSE4_2 1

#elif defined(__i386__) || defined(_M_IX86) || defined(__X86__)
#   undef ARCH_X86_32
#   undef ARCH_32BIT
#   undef ARCH_FAMILY_X86
#   define ARCH_X86_32 1
#   define ARCH_32BIT 1
#   define ARCH_FAMILY_X86 1

#   undef ARCH_HAS_MMX
#   undef ARCH_HAS_SSE
#   undef ARCH_HAS_SSE2
#   define ARCH_HAS_MMX 1
#   define ARCH_HAS_SSE 1
#   define ARCH_HAS_SSE2 1

#elif defined(__aarch64__) || defined(_M_ARM64)
#   undef ARCH_ARM64
#   undef ARCH_64BIT
#   undef ARCH_FAMILY_ARM
#   define ARCH_ARM64 1
#   define ARCH_64BIT 1
#   define ARCH_FAMILY_ARM 1

#   undef ARCH_HAS_NEON
#   undef ARCH_HAS_AES
#   undef ARCH_HAS_CRC32
#   define ARCH_HAS_NEON 1
#   define ARCH_HAS_AES 1
#   define ARCH_HAS_CRC32 1

#elif defined(__arm__) || defined(_M_ARM) || defined(__thumb__)
#   undef ARCH_ARM32
#   undef ARCH_32BIT
#   undef ARCH_FAMILY_ARM
#   define ARCH_ARM32 1
#   define ARCH_32BIT 1
#   define ARCH_FAMILY_ARM 1

#   if defined(__ARM_NEON) || defined(__ARM_NEON__)
#       undef ARCH_HAS_NEON
#       define ARCH_HAS_NEON 1
#   endif
#   if defined(__ARM_FEATURE_CRC32)
#       undef ARCH_HAS_CRC32
#       define ARCH_HAS_CRC32 1
#   endif

#elif defined(__riscv)
#   if __riscv_xlen == 64
#       undef ARCH_RISCV64
#       undef ARCH_64BIT
#       undef ARCH_FAMILY_RISCV
#       define ARCH_RISCV64 1
#       define ARCH_64BIT 1
#       define ARCH_FAMILY_RISCV 1
#   elif __riscv_xlen == 32
#       undef ARCH_RISCV32
#       undef ARCH_32BIT
#       undef ARCH_FAMILY_RISCV
#       define ARCH_RISCV32 1
#       define ARCH_32BIT 1
#       define ARCH_FAMILY_RISCV 1
#   else
#       error "Unsupported RISC-V XLEN"
#   endif

#   if defined(__riscv_vector)
#       undef ARCH_HAS_VECTOR
#       define ARCH_HAS_VECTOR 1
#   endif
#   if defined(__riscv_zba) || defined(__riscv_zbb) || defined(__riscv_zbc) || defined(__riscv_zbs)
#       undef ARCH_HAS_BITMANIP
#       define ARCH_HAS_BITMANIP 1
#   endif

#elif defined(__loongarch64)
#   undef ARCH_LOONGARCH64
#   undef ARCH_64BIT
#   undef ARCH_FAMILY_LOONGARCH
#   define ARCH_LOONGARCH64 1
#   define ARCH_64BIT 1
#   define ARCH_FAMILY_LOONGARCH 1

#elif defined(__mips__)
#   if defined(__mips64) && (_MIPS_SIM == _ABI64)
#       undef ARCH_MIPS64
#       undef ARCH_64BIT
#       undef ARCH_FAMILY_MIPS
#       define ARCH_MIPS64 1
#       define ARCH_64BIT 1
#       define ARCH_FAMILY_MIPS 1
#   elif defined(__mips__)
#       undef ARCH_MIPS32
#       undef ARCH_32BIT
#       undef ARCH_FAMILY_MIPS
#       define ARCH_MIPS32 1
#       define ARCH_32BIT 1
#       define ARCH_FAMILY_MIPS 1
#   endif

#elif defined(__powerpc64__) || defined(__ppc64__) || defined(_ARCH_PPC64)
#   undef ARCH_PPC64
#   undef ARCH_64BIT
#   undef ARCH_FAMILY_PPC
#   define ARCH_PPC64 1
#   define ARCH_64BIT 1
#   define ARCH_FAMILY_PPC 1

#elif defined(__powerpc__) || defined(__ppc__) || defined(_ARCH_PPC)
#   undef ARCH_PPC32
#   undef ARCH_32BIT
#   undef ARCH_FAMILY_PPC
#   define ARCH_PPC32 1
#   define ARCH_32BIT 1
#   define ARCH_FAMILY_PPC 1

#elif defined(__s390x__)
#   undef ARCH_S390X
#   undef ARCH_64BIT
#   undef ARCH_FAMILY_S390
#   define ARCH_S390X 1
#   define ARCH_64BIT 1
#   define ARCH_FAMILY_S390 1

#elif defined(__s390__)
#   undef ARCH_S390
#   undef ARCH_32BIT
#   undef ARCH_FAMILY_S390
#   define ARCH_S390 1
#   define ARCH_32BIT 1
#   define ARCH_FAMILY_S390 1

#elif defined(__sparc__)
#   if defined(__arch64__)
#       undef ARCH_SPARC64
#       undef ARCH_64BIT
#       undef ARCH_FAMILY_SPARC
#       define ARCH_SPARC64 1
#       define ARCH_64BIT 1
#       define ARCH_FAMILY_SPARC 1
#   else
#       undef ARCH_SPARC32
#       undef ARCH_32BIT
#       undef ARCH_FAMILY_SPARC
#       define ARCH_SPARC32 1
#       define ARCH_32BIT 1
#       define ARCH_FAMILY_SPARC 1
#   endif

#elif defined(__alpha__)
#   undef ARCH_ALPHA
#   undef ARCH_64BIT
#   undef ARCH_FAMILY_ALPHA
#   define ARCH_ALPHA 1
#   define ARCH_64BIT 1
#   define ARCH_FAMILY_ALPHA 1

#elif defined(__hppa__)
#   undef ARCH_HPPA
#   undef ARCH_32BIT
#   undef ARCH_FAMILY_HPPA
#   define ARCH_HPPA 1
#   define ARCH_32BIT 1
#   define ARCH_FAMILY_HPPA 1

#elif defined(__m68k__)
#   undef ARCH_M68K
#   undef ARCH_32BIT
#   undef ARCH_FAMILY_M68K
#   define ARCH_M68K 1
#   define ARCH_32BIT 1
#   define ARCH_FAMILY_M68K 1

#elif defined(__ia64__) || defined(_M_IA64)
#   undef ARCH_IA64
#   undef ARCH_64BIT
#   undef ARCH_FAMILY_IA64
#   define ARCH_IA64 1
#   define ARCH_64BIT 1
#   define ARCH_FAMILY_IA64 1

#else
#   error "Unsupported or unknown architecture"
#endif

// Helper macros for checking architecture and bitness (these work anywhere)
#define ARCH_is64BIT (ARCH_64BIT)
#define ARCH_is32BIT (ARCH_32BIT)

// Architecture family check macros
#define ARCH_isX86     (ARCH_FAMILY_X86)
#define ARCH_isARM     (ARCH_FAMILY_ARM)
#define ARCH_isRISCV   (ARCH_FAMILY_RISCV)
#define ARCH_isLOONGARCH (ARCH_FAMILY_LOONGARCH)
#define ARCH_isMIPS    (ARCH_FAMILY_MIPS)
#define ARCH_isPPC     (ARCH_FAMILY_PPC)
#define ARCH_isS390F   (ARCH_FAMILY_S390)
#define ARCH_isSPARC   (ARCH_FAMILY_SPARC)
#define ARCH_isALPHA   (ARCH_FAMILY_ALPHA)
#define ARCH_isHPPA    (ARCH_FAMILY_HPPA)
#define ARCH_isM68K    (ARCH_FAMILY_M68K)
#define ARCH_isIA64    (ARCH_FAMILY_IA64)

// Specific architecture check macros
#define ARCH_isX86_64       (ARCH_X86_64)
#define ARCH_isX86_32       (ARCH_X86_32)
#define ARCH_isARM64        (ARCH_ARM64)
#define ARCH_isARM32        (ARCH_ARM32)
#define ARCH_isRISCV64      (ARCH_RISCV64)
#define ARCH_isRISCV32      (ARCH_RISCV32)
#define ARCH_isLOONGARCH64  (ARCH_LOONGARCH64)
#define ARCH_isMIPS64       (ARCH_MIPS64)
#define ARCH_isMIPS32       (ARCH_MIPS32)
#define ARCH_isPPC64        (ARCH_PPC64)
#define ARCH_isPPC32        (ARCH_PPC32)
#define ARCH_isS390X        (ARCH_S390X)
#define ARCH_isS390         (ARCH_S390)
#define ARCH_isSPARC64      (ARCH_SPARC64)
#define ARCH_isSPARC32      (ARCH_SPARC32)

// Capability check macros
#define ARCH_hasMMX        (ARCH_HAS_MMX)
#define ARCH_hasSSE        (ARCH_HAS_SSE)
#define ARCH_hasSSE2       (ARCH_HAS_SSE2)
#define ARCH_hasSSE3       (ARCH_HAS_SSE3)
#define ARCH_hasSSSE3      (ARCH_HAS_SSSE3)
#define ARCH_hasSSE4_1     (ARCH_HAS_SSE4_1)
#define ARCH_hasSSE4_2     (ARCH_HAS_SSE4_2)
#define ARCH_hasNEON       (ARCH_HAS_NEON)
#define ARCH_hasAES        (ARCH_HAS_AES)
#define ARCH_hasCRC32      (ARCH_HAS_CRC32)
#define ARCH_hasVECTOR     (ARCH_HAS_VECTOR)
#define ARCH_hasBITMANIP   (ARCH_HAS_BITMANIP)

// Combined architecture groups
#define ARCH_isX86_FAMILY   (ARCH_FAMILY_X86)
#define ARCH_isARM_FAMILY   (ARCH_FAMILY_ARM)
#define ARCH_isRISC_V       (ARCH_FAMILY_RISCV)

// Check if at least one architecture was detected
#if !ARCH_isX86 && !ARCH_isARM && !ARCH_isRISCV && !ARCH_isLOONGARCH && \
    !ARCH_isMIPS && !ARCH_isPPC && !ARCH_isS390 && !ARCH_isSPARC && \
    !ARCH_isALPHA && !ARCH_isHPPA && !ARCH_isM68K && !ARCH_isIA64
#   error "No architecture detected - this should not happen"
#endif