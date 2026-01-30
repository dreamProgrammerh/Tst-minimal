import '../../runtime/context.dart';
import '../../runtime/values.dart';

final List<(String, int, BuiltinFunction)> solidFuncs = [
 ('int', 1, (args) {
   double x = args[0].asFloat();
   return IntValue(x.toInt());
 }),
 
 ('float', 1, (args) {
   double x = args[0].asFloat();
   return FloatValue(x);
 }),
 
 ('bool', 1, (args) {
   double x = args[0].asFloat();
   return IntValue(x == 0 ? 0 : 1);
 }), 
];