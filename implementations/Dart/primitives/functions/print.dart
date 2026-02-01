import '../../runtime/context.dart';
import '../../runtime/values.dart';
import '../../utils/log.dart' as Log;

@pragma('vm:prefer-inline')
String _buildString(List<RuntimeValue> args,
    String Function(RuntimeValue) fn,
    [String separator = ', ']) {
  StringBuffer sb = StringBuffer();
  
  for (int i = 0; i < args.length; i++) {
    if (i != 0)
      sb.write(separator);
    
    final v = args[i];
    sb.write(fn(v));
  }
  
  return sb.toString();
}

final List<BuiltinSignature> printFuncs = [
  ('info', [AT_extend | AT_any], ["values"], null, (args) {
    if (args.isEmpty) return InvalidValue.instance;
    
    print(_buildString(args, Log.stringInfo, '\n'));
    return args[0];
  }),
  
  ('print', [AT_extend | AT_any], ["values"], null, (args) {
    if (args.isEmpty) return InvalidValue.instance;
    
    print(_buildString(args, Log.stringValue));
    return args[0];
  }),
  
  ('printc', [AT_extend | AT_any], ["values"], null, (args) {
    if (args.isEmpty) return InvalidValue.instance;
    
    print(_buildString(args, Log.stringColor));
    return args[0];
  }),
  
  ('printo', [AT_extend | AT_any], ["values"], null, (args) {
    if (args.isEmpty) return InvalidValue.instance;
    
    print(_buildString(args, Log.stringCode));
    return args[0];
  }),
  
  ('printco', [AT_extend | AT_any], ["values"], null, (args) {
    if (args.isEmpty) return InvalidValue.instance;
    
    print(_buildString(args, (v) => '${Log.stringColor(v)} ${Log.stringCode(v)}'));
    return args[0];
  }),
];