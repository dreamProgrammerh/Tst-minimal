import 'context.dart';
import 'values.dart';

void initBuiltin() {
  registerFunction('rgba', (args) {
    if (args.length != 4) {
      RuntimeState.error('rgba expects 4 arguments');
      return InvalidValue.instance;
    }

    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;
    int a = args[3].asInt() & 0xff;

    return IntValue((a << 24) | (r << 16) | (g << 8) | b);
  });
  
  registerFunction('rgbo', (args) {
    if (args.length != 4) {
      RuntimeState.error('rgbo expects 4 arguments');
      return InvalidValue.instance;
    }

    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;
    int a = (args[3].asFloat() * 0xff).clamp(0, 0xff).toInt();

    return IntValue((a << 24) | (r << 16) | (g << 8) | b);
  });

  registerFunction('rgb', (args) {
    if (args.length != 3) {
      RuntimeState.error('rgb expects 3 arguments');
      return InvalidValue.instance;
    }

    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;

    return IntValue((0xff << 24) | (r << 16) | (g << 8) | b);
  });
}