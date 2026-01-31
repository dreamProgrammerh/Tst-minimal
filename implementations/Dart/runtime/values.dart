import '../error/errors.dart';
import '../error/reporter.dart';
import '../lexer/source.dart';

typedef int32   = int;
typedef float32 = double;
typedef Position = ({int start, int length});

abstract class RuntimeState {
  static late ErrorReporter _reporter;
  static late Source? _source;
  static List<Position> _positions = [];
    
  static void setup(Source? source, ErrorReporter reporter) {
    _source = source;
    _reporter = reporter;
  }
  
  static bool error(String msg) =>
    _reporter.push(RuntimeError(msg, current.start, current.length), source: _source);
  
  static Position get current => _positions.last;
  
  static Position pushPosition(Position pos) {
    _positions.add(pos);
    return pos;
  }
  
  static Position popPosition() =>
    _positions.removeLast();
}


abstract class RuntimeValue {
  int32 asInt();
  float32 asFloat();
  const RuntimeValue();
  
  String stringify() => '';
  @override
  String toString();
}

class InvalidValue extends RuntimeValue {
  static const InvalidValue instance = InvalidValue._();
  
  const InvalidValue._();

  @override
  float32 asFloat() {
    RuntimeState.error('Invalid cannot be float');
    return 0.0;
  }

  @override
  int32 asInt() {
    RuntimeState.error('Invalid cannot be int');
    return 0;
  }
  
  @override
  String stringify() => 'invalid';
  
  @override
  String toString() => '(invalid)';
}

class IntValue extends RuntimeValue {
  final int32 value;
  const IntValue(this.value);

  @override
  int32 asInt() => value;
  
  @override
  float32 asFloat() => value.toDouble();

  @override
  String stringify() => '$value';
  
  @override
  String toString() => '$value (int)';
}

class FloatValue extends RuntimeValue {
  final float32 value;
  const FloatValue(this.value);

  @override
  int32 asInt() => value.toInt();

  @override
  float32 asFloat() => value;

  @override
  String stringify() => '$value';
  
  @override
  String toString() => '$value (float)';
}
