import '../../runtime/context.dart';
import '../../runtime/values.dart';

final List<BuiltinSignature> solidFuncs = [
  ('int', [AT_int | AT_float], ["value"], null, (args) {
   return IntValue(args[0].asInt());
 }),
 
 ('float', [AT_int | AT_float], ["value"], null, (args) {
   return FloatValue(args[0].asFloat());
 }),
 
 ('bool', [AT_int | AT_float], ["value"], null, (args) {
   return IntValue(args[0].asInt() == 0 ? 0 : 1);
 }), 
];