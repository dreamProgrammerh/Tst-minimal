import '../constants/const-literals.dart' as LITERALS;
import '../constants/const-functions.dart' as FUNCTIONS;
import 'context.dart';
import 'values.dart';

bool _initialized = false; 
bool get initialized => _initialized;

void initBuiltin() {
  if (_initialized) return;
  _initialized = true;
  
  _initLiterals();
  _initFunctions();
}

void _initLiterals() {
   // Special
  for (final lit in LITERALS.specialLiterals)
    registerLiteral(lit.$1, lit.$2);
  
  // Math
  for (final lit in LITERALS.mathLiterals)
    registerLiteral(lit.$1, lit.$2);
  
  // Colors
  for (final lit in LITERALS.colorLiterals)
    registerLiteral(lit.$1, IntValue(lit.$2));
}

void _initFunctions() {
  for (final func in FUNCTIONS.builtinFunc)
    registerFunction(func.$1, func.$2);
  
  for (final func in FUNCTIONS.builtinFuncArgCount)
    registerFuncWithArgs(func.$1, func.$2, func.$3);  
}