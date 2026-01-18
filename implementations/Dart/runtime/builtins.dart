import '../utils/colors.dart' as Colors;
import 'context.dart';
import 'values.dart';

void initBuiltin() {
  registerFuncWithArgs('rgba', 4, (args) {
    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;
    int a = args[3].asInt() & 0xff;

    return IntValue((a << 24) | (r << 16) | (g << 8) | b);
  });
  
  registerFuncWithArgs('rgbo', 4, (args) {
    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;
    int a = (args[3].asFloat() * 0xff).clamp(0, 0xff).toInt();

    return IntValue((a << 24) | (r << 16) | (g << 8) | b);
  });

  registerFuncWithArgs('rgb', 3, (args) {
    int r = args[0].asInt() & 0xff;
    int g = args[1].asInt() & 0xff;
    int b = args[2].asInt() & 0xff;

    return IntValue((0xff << 24) | (r << 16) | (g << 8) | b);
  });

  registerFuncWithArgs('hex', 1, (args) {
    int code = args[0].asInt();

    return IntValue(Colors.hex(code));
  });
  
  registerFuncWithArgs('hslo', 4, (args) {
    double h = args[0].asFloat();
    double s = args[1].asFloat();
    double l = args[2].asFloat();
    double o = args[2].asFloat();

    return IntValue(Colors.hsl(h, s, l, o));
  });
  
  registerFuncWithArgs('hsl', 3, (args) {
    double h = args[0].asFloat();
    double s = args[1].asFloat();
    double l = args[2].asFloat();

    return IntValue(Colors.hsl(h, s, l));
  });
  
  registerFuncWithArgs('hsvo', 4, (args) {
    double h = args[0].asFloat();
    double s = args[1].asFloat();
    double v = args[2].asFloat();
    double o = args[2].asFloat();

    return IntValue(Colors.hsv(h, s, v, o));
  });
  
  registerFuncWithArgs('hsv', 3, (args) {
    double h = args[0].asFloat();
    double s = args[1].asFloat();
    double v = args[2].asFloat();

    return IntValue(Colors.hsv(h, s, v));
  });
}