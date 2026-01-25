import 'dart:ffi' as c;
import 'dart:io';

const _p = 'fmath_'; // prefix
final String? _libraryPath =
        Platform.isWindows ? "lib/fastMath.dll"
      : Platform.isMacOS ? "lib/fastMath.dylib"
      : Platform.isLinux ? "lib/fastMath.so"
      : null;
      
late final c.DynamicLibrary _lib;

void load_fmathLib() {
  if (_libraryPath == null)
    throw UnsupportedError("Unsupported Operating System: ${Platform.operatingSystem}");
  
  _lib = c.DynamicLibrary.open(_libraryPath!);
}

final now = _lib
  .lookupFunction<c.Uint64 Function(), int Function()>('${_p}now');