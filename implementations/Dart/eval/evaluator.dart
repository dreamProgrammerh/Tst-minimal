import '../error/reporter.dart';
import '../lexer/source.dart';
import '../parser/ast.dart';
import '../runtime/context.dart';
import '../runtime/values.dart';

class Evaluator {
  final Program program;
  final ErrorReporter reporter;
  final Source? source;
  
  const Evaluator(this.program, {required this.reporter, this.source});
  
  EvalMap eval() {
    RuntimeState.setup(source, reporter);
    final ctx = EvalContext(program, reporter: reporter);
    
    EvalMap map = {};
    
    for (final decl in program.declarations) {
      RuntimeState.pushPosition(decl.expr.position);
      final value = decl.expr.eval(ctx);
      RuntimeState.popPosition();
      map[decl.name] = value;
    }
    
    return map;
  }
}