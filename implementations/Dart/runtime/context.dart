import '../eval/evaluator.dart';
import '../parser/ast.dart';
import '../utils/help.dart';
import 'results.dart';
import 'values.dart';

// AT short for Argument Type

const AT_extend   = 1 << 0;
const AT_optional = 1 << 1;
const AT_none     = 1 << 2;
const AT_any      = 1 << 3;
const AT_int      = 1 << 4;
const AT_float    = 1 << 5;

const AL_Types    = [AT_extend, AT_optional, AT_none, AT_any, AT_int, AT_float];
const AL_Names    = ["Extend", "Optional", "none", "any", "int", "float"];
const AL_Idx      = 2;

typedef Signature         = List<int>;
typedef BuiltinLiteral    = RuntimeValue;
typedef BuiltinFunction   = RuntimeValue Function(List<RuntimeValue> args);
typedef RuntimeFunction   = RuntimeValue Function(List<RuntimeValue> args);
typedef BuiltinSignature  = (
  String name,
  Signature? signature,
  List<String>? names,
  String? help,
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

void registerFuncSignature(BuiltinSignature signature) {
  final sigName = signature.$1;
  final sigTypes = signature.$2;
  final sigArgNames = signature.$3;
  final sigHelpFile = signature.$4;
  final sigFn = signature.$5;

  if (sigTypes == null) {
    _builtinFunctions[sigName] = sigFn;
    return;
  }

  final (
    bool extended,
    int optionalCount,
    bool error) = _validateArgs(sigTypes);

  if (error) return;

  if (sigHelpFile != null && sigHelpFile.trim().isNotEmpty)
    registerHelp(sigName, sigHelpFile.trim());

  final BuiltinFunction func = (args) {
    // Calculate minimum and maximum allowed arguments
    int minArgs;
    int maxArgs;

    if (extended) {
      // Extended: min = all required args, max = unlimited
      minArgs = sigTypes.length - 1;  // All except the extended one
      maxArgs = -1;                   // -1 means unlimited
    } else if (optionalCount > 0) {
      // Optionals: min = required args, max = all args
      minArgs = sigTypes.length - optionalCount;
      maxArgs = sigTypes.length;
    } else {
      // Fixed: exact number required
      minArgs = sigTypes.length;
      maxArgs = sigTypes.length;
    }

    // Check argument count
    if (args.length < minArgs || (maxArgs != -1 && args.length > maxArgs)) {
      final expectedSig = stringifySignature(sigTypes, sigArgNames, sigName);

      String expectedCount = extended
        ? 'at least $minArgs'
        : optionalCount > 0
        ? 'between $minArgs and $maxArgs'
        : 'exactly $minArgs';

      RuntimeState.error(
        'Function "$sigName" expects $expectedCount arguments, '
        'but got ${args.length}. Expected signature: $expectedSig'
      );
      return InvalidValue.instance;
    }

    // Check argument types
    for (int i = 0; i < args.length; i++) {
      int typeMask;

      // Determine which type mask to use based on position
      if (extended && i >= sigTypes.length - 1) {
        // For extended arguments, use the last type mask
        typeMask = sigTypes.last;
      } else if (i < sigTypes.length) {
        // Regular argument
        typeMask = sigTypes[i];
      } else {
        // Should not happen due to previous validation
        RuntimeState.error('Internal error: argument index out of bounds');
        return InvalidValue.instance;
      }

      // Remove extend/optional flags for type checking (keep only type bits)
      final typeBits = typeMask & ~(AT_extend | AT_optional);

      // Check if type matches
      final match = typeBits & AT_any != 0 || _typeMatches(args[i], typeBits);
      if (!match) {
        final expectedSig   = stringifySignature(sigTypes, sigArgNames, sigName);
        final expectedType  = _getTypeName(typeBits);
        final actualType    = _getValueTypeName(args[i]);

        RuntimeState.error(
          'Argument ${i + 1} "${sigArgNames?[i < sigArgNames.length ? i : i]} of function "$sigName" should be of type '
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
    case InvalidValue _:  return 2;   // AT_none
    case IntValue _:      return 4;   // AT_int
    case FloatValue _:    return 5;   // AT_float
    default:              return -1;  // unknown
  }
}

@pragma('vm:prefer-inline')
(bool extended, int optionalCount, bool error) _validateArgs(Signature s) {
  int optionalCount = 0;
  bool extended = false;

  for (int i = 0; i < s.length; i++) {
    final t = s[i];
    final extendArg = t & AT_extend != 0;
    final optionalArg = t & AT_optional != 0;

    // Check for both flags in the same argument
    if (extendArg && optionalArg) {
      RuntimeState.error('argument cannot be both extended and optional');
      return (false, 0, true);
    }

    // Check for extend flag
    if (extendArg) {
      if (extended) {
        RuntimeState.error('only one extended argument is allowed');
        return (false, 0, true);
      }

      extended = true;

      // Extended must be at the end
      if (i != s.length - 1) {
        RuntimeState.error('extended argument must be at end');
        return (false, 0, true);
      }

      // Cannot mix extend with optional
      if (optionalCount > 0) {
        RuntimeState.error('extended and optional arguments cannot be mixed');
        return (false, 0, true);
      }
    }

    // Check for optional flag
    else if (optionalArg) {
      optionalCount++;
    }

    // Not optional, not extend - this is a required argument
    else {
      // If In optional follow up
      if (optionalCount > 0) {
        RuntimeState.error('required argument cannot follow optional arguments');
        return (false, 0, true);
      }
    }
  }

  return (extended, optionalCount, false);
}

// Helper function to check if a value matches expected type
@pragma('vm:prefer-inline')
bool _typeMatches(RuntimeValue value, int expectedTypeMask) {
  if (expectedTypeMask == AT_none) return true;
  
  final index = _getValueTypeIndex(value);
  if (index == -1) return false;
  
  final valueType = AL_Types[index];
  
  // Check if the value's type is in the allowed mask
  return (expectedTypeMask & valueType) != 0;
}

// Helper function to get type name for error messages
@pragma('vm:prefer-inline')
String _getTypeName(int typeMask) {
  final List<String> names = [];
  for (int i = 0; i < AL_Types.length; i++) {
    if (typeMask & AL_Types[i] != 0) {
      names.add(AL_Names[i]);
    }
  }
  return names.join(' | ');
}

// Helper function to get the actual type name of a RuntimeValue
@pragma('vm:prefer-inline')
String _getValueTypeName(RuntimeValue value) {
  final index = _getValueTypeIndex(value);
  if (index == -1) return 'unknown';
  
  return AL_Names[index];
}

String stringifySignature(Signature s, [List<String>? names, String? fnName]) {
  final sb = StringBuffer(fnName == null ? '' : '$fnName(');
  
  int I = 0;
  for (final types in s) {
    if (I != 0) sb.write(', ');
    
    final extendArg = types & AT_extend != 0;
    final optionalArg = types & AT_optional != 0;
    
    final name = names?[I];
    if (name != null)
      sb.write('${extendArg ? '...' : ''}$name${optionalArg ? '?' : ''}: ');
      
    else if (extendArg || optionalArg)
      sb.write('${extendArg ? '...' : ''}${optionalArg ? '?' : ''} ');
    
    int J = 0;
    for (int i = AL_Idx; i < AL_Types.length; i++) {
      final type = AL_Types[i];
      if (types & type != 0) {
        if (J != 0) sb.write(' | ');
        sb.write(AL_Names[i]);
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