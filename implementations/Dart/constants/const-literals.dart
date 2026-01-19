import '../runtime/values.dart';

const List<(String, RuntimeValue)> specialLiterals = [
  ('invalid', InvalidValue.instance),
  ('true', IntValue(1)),
  ('false', IntValue(0)),
];

const List<(String, RuntimeValue)> mathLiterals = [
  ('PI', FloatValue(3.1415926535897932)),
  ('E', FloatValue(2.718281828459045)),
];

const List<(String, int)> colorLiterals = [
  ('transparent', 0x00000000),
  ('black', 0xFF000000),
  ('white', 0xFFFFFFFF),
  ('red', 0xFFFF0000),
  ('green', 0xFF00FF00),
  ('blue', 0xFF0000FF),
  ('yellow', 0xFFFFFF00),
  ('cyan', 0xFF00FFFF),
  ('magenta', 0xFFFF00FF),
];