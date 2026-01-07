import '../runtime/context.dart';
import '../runtime/values.dart';

class Declaration {
  final String name;
  final Expr expr;
  final Position position;
  
  const Declaration(this.name, this.expr, this.position);
}

class Program {
  final List<Declaration> declarations;
  
  const Program(this.declarations);
}

abstract class Expr {
  RuntimeValue eval(EvalContext ctx);
}