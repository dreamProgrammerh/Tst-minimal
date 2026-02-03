import '../primitives/functions/colors.dart';
import '../primitives/functions/math.dart';
import '../primitives/functions/print.dart';
import '../primitives/functions/solid.dart';
import '../primitives/literals/colors.dart';
import '../primitives/literals/math.dart';
import '../primitives/literals/special.dart';
import 'repl.dart' as repl;

late List<String> replCompletions;

void initCompletions() {
  final completions = <String>[];
  
  // Add Color Names (blue, red, etc.)
  for (final c in colorLiterals)
    completions.add(c.$1);
    
  // Add special literals names (true, false, etc.)
  for (final l in specialLiterals)
    completions.add(l.$1);
  
  // Add math constants (PI, E, etc.)
  for (final m in mathLiterals)
    completions.add(m.$1);
  
  // Add color functions (hue(), hsl(), etc.)
  for (final colorf in colorFuncs)
    completions.add('${colorf.$1}()');
  
  // Add math functions (abs(), min(), etc.)
  for (final mathf in mathFuncs)
    completions.add('${mathf.$1}()');
  
  // Add solid functions (int(), float(), bool())
  for (final solidf in solidFuncs)
    completions.add('${solidf.$1}()');
  
  // Add print functions (print(), printc(), etc.)
  for (final printf in printFuncs)
    completions.add('${printf.$1}()');
    
  completions.sort((a, b) => a.length - b.length);
  
  repl.addAllCompletion(completions);
  replCompletions = List.unmodifiable(completions);
}