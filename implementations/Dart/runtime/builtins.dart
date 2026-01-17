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

    return IntValue((r << 24) | (g << 16) | (b << 8) | a);
  });

  registerFunction('rgb', (args) {
    if (args.length != 3) {
      RuntimeState.error('rgb expects 3 arguments');
      return InvalidValue.instance;
    }

    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;

    return IntValue((r << 24) | (g << 16) | (b << 8) | 0xff);
  });
}