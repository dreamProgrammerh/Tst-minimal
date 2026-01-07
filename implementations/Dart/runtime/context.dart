import '../error/reporter.dart';
import '../parser/ast.dart';
import 'values.dart';

typedef BuiltinFunction = RuntimeValue Function(List<RuntimeValue> args);
typedef RuntimeFunction = RuntimeValue Function(List<RuntimeValue> args);
 
final Map<String, BuiltinFunction> _builtinFunctions = {};

void registerFunction(String name, BuiltinFunction fn) {
  _builtinFunctions[name] = fn;
}

class EvalContext {
  final Program program;
  final ErrorReporter reporter;

  final Map<String, RuntimeValue> values = {};
  final Map<String, RuntimeFunction> functions = {};
  final Set<String> stack = {};

  late final Map<String, Declaration> declMap;

  EvalContext(this.program, {required this.reporter}) {
    declMap = {
      for (final d in program.declarations) d.name: d
    };
  }
  
  RuntimeFunction? getFunction(String name) => _builtinFunctions[name] ?? functions[name];

  RuntimeValue resolve(String name) {
    if (values.containsKey(name)) return values[name]!;

    final decl = declMap[name];
    if (decl == null) {
      _error('Unknown variable: $name');
      return InvalidValue.instance;
    }

    if (!stack.add(name)) {
      _error('Cyclic reference: $name');
      return InvalidValue.instance;
    }

    RuntimeState.pushPosition(decl.position);
    final value = decl.expr.eval(this);
    RuntimeState.popPosition();

    stack.remove(name);
    values[name] = value;
    return value;
  }

  bool _error(String msg) =>
    RuntimeState.error(msg);
}