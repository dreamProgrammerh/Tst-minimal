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
  ('info', null, null, null, (args) {
    if (args.length == 0) {
      RuntimeState.error('info need at least one arguments');
      return InvalidValue.instance;
    }
    
    print(_buildString(args, Log.stringInfo, '\n'));
    return args[0];
  }),
  
  ('print', null, null, null, (args) {
    if (args.length == 0) {
      RuntimeState.error('print need at least one arguments');
      return InvalidValue.instance;
    }
    
    print(_buildString(args, Log.stringValue));
    return args[0];
  }),
  
  ('printc', null, null, null, (args) {
    if (args.length == 0) {
      RuntimeState.error('printc need at least one arguments');
      return InvalidValue.instance;
    }
    
    print(_buildString(args, Log.stringColor));
    return args[0];
  }),
  
  ('printo', null, null, null, (args) {
    if (args.length == 0) {
      RuntimeState.error('printo need at least one arguments');
      return InvalidValue.instance;
    }
    
    print(_buildString(args, Log.stringCode));
    return args[0];
  }),
  
  ('printco', null, null, null, (args) {
    if (args.length == 0) {
      RuntimeState.error('printco need at least one arguments');
      return InvalidValue.instance;
    }
    
    print(_buildString(args, (v) => '${Log.stringColor(v)} ${Log.stringCode(v)}'));
    return args[0];
  }),
];