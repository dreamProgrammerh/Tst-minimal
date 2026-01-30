import '../eval/evaluator.dart';
import '../parser/ast.dart';
import 'results.dart';
import 'values.dart';

typedef BuiltinLiteral  = RuntimeValue;
typedef BuiltinFunction = RuntimeValue Function(List<RuntimeValue> args);
typedef RuntimeFunction = RuntimeValue Function(List<RuntimeValue> args);
 
final Map<String, BuiltinLiteral> _builtinLiterals = {};
final Map<String, BuiltinFunction> _builtinFunctions = {};

void registerLiteral(String name, BuiltinLiteral lit) {
  _builtinLiterals[name] = lit;
}

void registerFunction(String name, BuiltinFunction fn) {
  _builtinFunctions[name] = fn;
}

// TODO: imporve arg api to accept multi types
void registerFuncWithArgs(String name, int argsCount, BuiltinFunction fn) {
  BuiltinFunction func = (args) {
    if (argsCount == -1) return fn(args);
    
    if (args.length != argsCount) {
      RuntimeState.error('$name ${
        args.length > 0
          ? "expects $argsCount arguments"
          : "doesn't expects any argument"
      }');
      return InvalidValue.instance;
    }
    
    return fn(args);
  };
  
  _builtinFunctions[name] = func;
}

class EvalContext {
  final Program program;

  final EvalMap map = EvalMap({});
  final Map<String, RuntimeFunction> functions = {};
  final Set<String> stack = {};

  late final Map<String, Declaration> declMap;

  EvalContext(this.program) {
    declMap = {
      for (final d in program.declarations) 
        if (d.name != null) d.name! : d
    };
  }
  
  BuiltinLiteral? getLiteral(String name)   => _builtinLiterals[name];
  RuntimeFunction? getFunction(String name) => _builtinFunctions[name] ?? functions[name];

  RuntimeValue resolve(String name) {
    if (map.map.containsKey(name)) return map[name]!;

    final decl = declMap[name];
    if (decl == null) {
      _error('Unknown variable: $name');
      return InvalidValue.instance;
    }

    if (!stack.add(name)) {
      _error('Cyclic reference: $name');
      return InvalidValue.instance;
    }

    final value = Evaluator.evaluate(decl.expr, this);

    stack.remove(name);
    map[name] = value;
    return value;
  }

  bool _error(String msg) =>
    RuntimeState.error(msg);
}