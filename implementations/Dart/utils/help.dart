import 'dart:io';

const helpMain = './help/';

final Map<String, String> _helpFiles = {};
final Map<String, String> _helpCatch = {};

void registerHelp(String name, String help) {
  _helpFiles[name] = help;
}

String getHelp(String name) {
  final path = _helpFiles[name];
  if (path == null) return "No help found for '$name'";
  
  final c = _helpCatch[name];
  if (c != null) return c;
  
  try {
    final file = File('$helpMain$path');
    final content = file.readAsStringSync();
    _helpCatch[name] = content;
    return content;
  } catch (e) {
    return 'Error reading help file: $e';
  }
}