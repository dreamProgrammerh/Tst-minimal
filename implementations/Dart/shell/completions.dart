import '../primitives/functions/colors.dart';
import '../primitives/functions/math.dart';
import '../primitives/functions/print.dart';
import '../primitives/functions/solid.dart';
import '../primitives/literals/colors.dart';
import '../primitives/literals/math.dart';
import '../primitives/literals/special.dart';
import 'repl.dart' as repl;

void initCompletions() {
  // Add Color Names (blue, red, etc.)
  for (final c in colorLiterals)
    repl.addCompletion(c.$1);
    
  // Add special literals names (true, false, etc.)
  for (final l in specialLiterals)
    repl.addCompletion(l.$1);
  
  // Add math constants (PI, E, etc.)
  for (final m in mathLiterals)
    repl.addCompletion(m.$1);
  
  // Add color functions (hue(), hsl(), etc.)
  for (final colorf in colorFuncs)
    repl.addCompletion('${colorf.$1}()');
  
  // Add math functions (abs(), min(), etc.)
  for (final mathf in mathFuncs)
    repl.addCompletion('${mathf.$1}()');
  
  // Add solid functions (int(), float(), bool())
  for (final solidf in solidFuncs)
    repl.addCompletion('${solidf.$1}()');
  
  // Add print functions (print(), printc(), etc.)
  for (final printf in printFuncs)
    repl.addCompletion('${printf.$1}()');
}