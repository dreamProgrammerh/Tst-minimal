import '../../runtime/values.dart';

const List<(String, RuntimeValue)> specialLiterals = [
  ('invalid', InvalidValue.instance),
  ('true', IntValue(1)),
  ('false', IntValue(0)),
];