import '../eval/evaluator.dart';
import '../parser/ast.dart';
import '../utils/help.dart';
import 'results.dart';
import 'values.dart';

const AT_none    = 1 << 1;
const AT_int     = 1 << 2;
const AT_float   = 1 << 3;

const AT_Types    = [AT_none, AT_int, AT_float];
const AT_Values   = [AT_none, IntValue, AT_float];
const AT_Names    = ["none", "int", "float"];

typedef Signature         = List<int>;
typedef BuiltinLiteral    = RuntimeValue;
typedef BuiltinFunction   = RuntimeValue Function(List<RuntimeValue> args);
typedef RuntimeFunction   = RuntimeValue Function(List<RuntimeValue> args);
typedef BuiltinSignature  = (
  String name,
  Signature signature,
  List<String> names,
  String help,
  BuiltinFunction fn
);
 
final Map<String, BuiltinLiteral> _builtinLiterals = {};
final Map<String, BuiltinFunction> _builtinFunctions = {};


void registerLiteral(String name, BuiltinLiteral lit) {
  _builtinLiterals[name] = lit;
}

void registerFunction(String name, BuiltinFunction fn) {
  _builtinFunctions[name] = fn;
}

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

void registerFuncSignature(BuiltinSignature signature) {
  final sigName = signature.$1;
  final sigTypes = signature.$2;
  final sigArgNames = signature.$3;
  final sigHelpFile = signature.$4.trim();
  final sigFn = signature.$5;
  
  if (sigHelpFile.isNotEmpty)
    registerHelp(sigName, sigHelpFile);
  
  final BuiltinFunction func = (args) {
    // Check argument count
    if (args.length != sigTypes.length) {
      final expectedSig = stringifySignature(sigTypes, sigArgNames, sigName);
      RuntimeState.error(
        'Function "$sigName" expects ${sigTypes.length} arguments, '
        'but got ${args.length}. Expected signature: $expectedSig'
      );
      return InvalidValue.instance;
    }
    
    // Check argument types
    for (int i = 0; i < args.length; i++) {
      if (!_typeMatches(args[i], sigTypes[i])) {
        final expectedSig = stringifySignature(sigTypes, sigArgNames, sigName);
        final expectedType = _getTypeName(sigTypes[i]); 
        final actualType = _getValueTypeName(args[i]);
        
        RuntimeState.error(
          'Argument ${i + 1} of function "$sigName" should be of type '
          '$expectedType, but got $actualType. '
          'Expected signature: $expectedSig'
        );
        return InvalidValue.instance;
      }
    }
    
    // All checks passed, execute the function
    try {
      return sigFn(args);
    } catch (e) {
      RuntimeState.error('Error executing function "$sigName": $e');
      return InvalidValue.instance;
    }
  };
  
  _builtinFunctions[sigName] = func;
}

// Helper function to find the index of runtime type in AT_Types
@pragma('vm:prefer-inline')
int _getValueTypeIndex(RuntimeValue value) {
  switch (value) {
    case InvalidValue _: return 0;  // AT_none
    case IntValue _: return 1;      // AT_int
    case FloatValue _: return 2;    // AT_float
    default: return -1;             // unknown
  }
}

// Helper function to check if a value matches expected type
@pragma('vm:prefer-inline')
bool _typeMatches(RuntimeValue value, int expectedTypeMask) {
  if (expectedTypeMask == AT_none) return true;
  
  final index = _getValueTypeIndex(value);
  if (index == -1) return false;
  
  final valueType = AT_Types[index];
  
  // Check if the value's type is in the allowed mask
  return (expectedTypeMask & valueType) != 0;
}

// Helper function to get type name for error messages
@pragma('vm:prefer-inline')
String _getTypeName(int typeMask) {
  final List<String> names = [];
  for (int i = 0; i < AT_Types.length; i++) {
    if (typeMask & AT_Types[i] != 0) {
      names.add(AT_Names[i]);
    }
  }
  return names.join(' | ');
}

// Helper function to get the actual type name of a RuntimeValue
@pragma('vm:prefer-inline')
String _getValueTypeName(RuntimeValue value) {
  final index = _getValueTypeIndex(value);
  if (index == -1) return 'unknown';
  
  return AT_Names[index];
}

String stringifySignature(Signature s, [List<String>? names, String? fnName]) {
  final sb = StringBuffer(fnName == null ? '' : '$fnName(');
  
  int I = 0;
  for (final types in s) {
    if (I != 0) sb.write(', ');
    
    final name = names?[I];
    if (name != null) sb.write('$name: ');
    
    int J = 0;
    for (int i = 0; i < AT_Types.length; i++) {
      final type = AT_Types[i];
      if (types & type != 0) {
        if (J != 0) sb.write(' | ');
        sb.write(AT_Names[i]);
        J++;
      }
    }
    I++;
  }
  
  if (fnName != null) sb.write(')');
  return sb.toString();
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