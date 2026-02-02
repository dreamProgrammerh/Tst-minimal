// rawmode.dart
//
// Cross‑platform raw mode control using:
// - Windows: Win32 console APIs via FFI
// - Unix: stdin.lineMode / stdin.echoMode
// - libc calloc/free (no ffi.calloc)
//
// Usage:
//   setRawMode(raw: true);
//   setRawMode(raw: false); // restore

import 'dart:ffi' as ffi;
import 'dart:io';

// -----------------------------
// libc calloc/free
// -----------------------------
typedef CCalloc = ffi.Pointer<ffi.Void> Function(ffi.Size, ffi.Size);
typedef DartCalloc = ffi.Pointer<ffi.Void> Function(int, int);

typedef CFree = ffi.Void Function(ffi.Pointer<ffi.Void>);
typedef DartFree = void Function(ffi.Pointer<ffi.Void>);

final ffi.DynamicLibrary _libc = Platform.isWindows
    ? ffi.DynamicLibrary.open('msvcrt.dll')
    : ffi.DynamicLibrary.process();

final DartCalloc ccalloc =
    _libc.lookupFunction<CCalloc, DartCalloc>('calloc');

final DartFree cfree =
    _libc.lookupFunction<CFree, DartFree>('free');

// -----------------------------
// WinAPI FFI
// -----------------------------
typedef _GetStdHandleC = ffi.IntPtr Function(ffi.Uint32);
typedef _GetStdHandleDart = int Function(int);

typedef _GetConsoleModeC = ffi.Int32 Function(
    ffi.IntPtr, ffi.Pointer<ffi.Uint32>);
typedef _GetConsoleModeDart = int Function(int, ffi.Pointer<ffi.Uint32>);

typedef _SetConsoleModeC = ffi.Int32 Function(ffi.IntPtr, ffi.Uint32);
typedef _SetConsoleModeDart = int Function(int, int);

class RawConsole {
  static bool _initialized = false;
  static bool _isWindows = Platform.isWindows;

  // Windows fields
  static late ffi.DynamicLibrary _kernel32;
  static late _GetStdHandleDart _GetStdHandle;
  static late _GetConsoleModeDart _GetConsoleMode;
  static late _SetConsoleModeDart _SetConsoleMode;

  static const int _STD_INPUT_HANDLE = -10;

  static int _hStdin = 0;
  static int _originalMode = 0;

  static void _initWindows() {
    if (_initialized) return;
    _initialized = true;

    _kernel32 = ffi.DynamicLibrary.open('kernel32.dll');

    _GetStdHandle = _kernel32.lookupFunction<
        _GetStdHandleC, _GetStdHandleDart>('GetStdHandle');

    _GetConsoleMode = _kernel32.lookupFunction<
        _GetConsoleModeC, _GetConsoleModeDart>('GetConsoleMode');

    _SetConsoleMode = _kernel32.lookupFunction<
        _SetConsoleModeC, _SetConsoleModeDart>('SetConsoleMode');

    _hStdin = _GetStdHandle(_STD_INPUT_HANDLE);

    // allocate using libc calloc
    final modePtr = ccalloc(1, ffi.sizeOf<ffi.Uint32>())
        .cast<ffi.Uint32>();

    _GetConsoleMode(_hStdin, modePtr);
    _originalMode = modePtr.value;

    cfree(modePtr.cast());
  }

  /// Enable or disable raw mode.
  static void setRawMode({
    bool raw = true,
    bool echo = false,
    bool line = false,
    bool ctrlC = false,
  }) {
    if (_isWindows) {
      _initWindows();
      _setWindowsRawMode(raw, echo, line, ctrlC);
    } else {
      _setUnixRawMode(raw, echo, line);
    }
  }

  // -----------------------------
  // UNIX (Linux/macOS)
  // -----------------------------
  static void _setUnixRawMode(bool raw, bool echo, bool line) {
    try {
      stdin.echoMode = raw ? echo : true;
      stdin.lineMode = raw ? line : true;
    } catch (_) {
      // Terminal does not support raw mode
    }
  }

  // -----------------------------
  // WINDOWS
  // -----------------------------
  static void _setWindowsRawMode(
      bool raw, bool echo, bool line, bool ctrlC) {
    if (!raw) {
      // Restore original mode
      _SetConsoleMode(_hStdin, _originalMode);
      return;
    }

    // Windows console mode flags
    const ENABLE_ECHO_INPUT = 0x0004;
    const ENABLE_LINE_INPUT = 0x0002;
    const ENABLE_PROCESSED_INPUT = 0x0001;
    const ENABLE_VIRTUAL_TERMINAL_INPUT = 0x0200;

    int mode = _originalMode;

    // Line mode
    if (line) {
      mode |= ENABLE_LINE_INPUT;
    } else {
      mode &= ~ENABLE_LINE_INPUT;
    }

    // Echo
    if (echo) {
      mode |= ENABLE_ECHO_INPUT;
    } else {
      mode &= ~ENABLE_ECHO_INPUT;
    }

    // Ctrl+C processing
    if (ctrlC) {
      mode |= ENABLE_PROCESSED_INPUT;
    } else {
      mode &= ~ENABLE_PROCESSED_INPUT;
    }

    // Enable raw ANSI input
    mode |= ENABLE_VIRTUAL_TERMINAL_INPUT;

    _SetConsoleMode(_hStdin, mode);
  }
}

// Public API
void setRawMode({
  bool raw = true,
  bool echo = false,
  bool line = false,
  bool ctrlC = false,
}) {
  RawConsole.setRawMode(
    raw: raw,
    echo: echo,
    line: line,
    ctrlC: ctrlC,
  );
}
