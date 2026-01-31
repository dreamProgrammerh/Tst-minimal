import '../../runtime/values.dart';

const List<(String, RuntimeValue)> mathLiterals = [
  ('HPI', FloatValue(1.5707963267948966)),
  ('PI', FloatValue(3.1415926535897932)),
  ('TAU', FloatValue(6.283185307179586)),
  ('E', FloatValue(2.718281828459045)),
  ('NaN', FloatValue(double.nan)),
  ('Infinity', FloatValue(double.infinity)),
  ('DTR', FloatValue(0.017453292519943295)),  // degree to radain
  ('RTD', FloatValue(57.29577951308232)),     // radian to degree
  ('CDist', FloatValue(441.6729559300637)),   // rgb color max distance
];