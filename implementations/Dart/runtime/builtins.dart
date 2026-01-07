import 'context.dart';
import 'values.dart';

void initBuiltin() {
  registerFunction('rgba', (args) {
    if (args.length != 4)
      throw FormatException('rgba expects 4 arguments');

    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;
    int a = args[3].asInt() & 0xff;

    return IntValue((r << 24) | (g << 16) | (b << 8) | a);
  });

  registerFunction('rgba', (args) {
    if (args.length != 4)
      throw FormatException('rgba expects 4 arguments');

    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;
    int a = args[3].asInt() & 0xff;

    return IntValue((r << 24) | (g << 16) | (b << 8) | a);
  });
}