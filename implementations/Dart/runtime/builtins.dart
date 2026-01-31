import '../primitives/functions/colors.dart';
import '../primitives/functions/math.dart';
import '../primitives/functions/print.dart';
import '../primitives/functions/solid.dart';
import '../primitives/literals/colors.dart';
import '../primitives/literals/math.dart';
import '../primitives/literals/special.dart';
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
  for (final lit in specialLiterals)
    registerLiteral(lit.$1, lit.$2);
  
  // Math
  for (final lit in mathLiterals)
    registerLiteral(lit.$1, lit.$2);
  
  // Colors
  for (final lit in colorLiterals)
    registerLiteral(lit.$1, IntValue(lit.$2));
}

void _initFunctions() {
  // Solid
  for (final func in solidFuncs)
    registerFuncSignature(func);  
  
  // Print
  for (final func in printFuncs)
    registerFuncSignature(func);  
    
  // Math
  for (final func in mathFuncs)
    registerFuncSignature(func);  
  
  // Colors
  for (final func in colorFuncs)
    registerFuncSignature(func);
}