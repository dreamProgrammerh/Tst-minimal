import 'dart:io';

class Source {
  final String src;
  final String? path;
  
  int get length => src.length;
  String? get name => path == null ? null : _getFileName(path!);
  
  const Source(this.src, [this.path]);

  static Future<Source?> from(String path) async {
    final file = File(path);
    if (! await file.exists())
      return null;

    return Source(await file.readAsString(), _getFileName(path));
  }

  static String _getFileName(String path) {
    return path.substring((path.lastIndexOf('/') + 1).clamp(0, path.length - 1), path.length);
  }

  String chunk(int start, [int? end]) {
    return src.substring(start, end);
  }

  String operator [](int index) {
    return src[index];
  }

  @override
  String toString() => src;
}

class MSource extends Source {
  String src;
  String? path;
  MSource(this.src, [this.path]): super('', null);
}