import 'dart:ffi' as c;
import 'dart:io';

const _p = 'fmath_'; // prefix
final String? _libraryPath =
        Platform.isWindows ? "lib/fastMath.dll"
      : Platform.isMacOS ? "lib/fastMath.dylib"
      : Platform.isLinux ? "lib/fastMath.so"
      : null;
      
late final _lib;

void load_fmathLib() {
  if (_libraryPath == null)
    throw UnsupportedError("Unsupported Operating System: ${Platform.operatingSystem}");
  
  _lib = c.DynamicLibrary.open(_libraryPath!);
}

dynamic _loadFunc<T extends Function>(String name) => _lib
  .lookup<c.NativeFunction<T>>(name)
  .asFunction();

final int Function() now = _loadFunc<c.Uint64 Function()>('${_p}now');