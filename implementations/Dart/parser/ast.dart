import '../lexer/lexer.dart';
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

// ~~~~~~~~~~~~~~~~~~~~~~
//      Expressions
// ~~~~~~~~~~~~~~~~~~~~~~

abstract class Expr {
  final Position position;
  const Expr(this.position);
}

class InvalidExpr extends Expr {
  static const instance = InvalidExpr._((start: -1, length: 0));
  
  const InvalidExpr._(super.position);
}

class IntExpr extends Expr {
  final int value;
  const IntExpr(this.value, super.position);
}

class LiteralExpr extends Expr {
  final String literal;
  const LiteralExpr(this.literal, super.position);
}

class FloatExpr extends Expr {
  final double value;
  const FloatExpr(this.value, super.position);
}

class VarExpr extends Expr {
  final String name;
  const VarExpr(this.name, super.position);
}

class CallExpr extends Expr {
  final String name;
  final List<Expr> args;

  const CallExpr(this.name, this.args, super.position);
}

class NotExpr extends Expr {
  final Expr expr;
  const NotExpr(this.expr, super.position);
}

class UnaryExpr extends Expr {
  final TokenType op;
  final Expr expr;

  const UnaryExpr(this.op, this.expr, super.position);
}

class BinaryExpr extends Expr {
  final Expr left;
  final TokenType op;
  final Expr right;
  
  const BinaryExpr(this.left, this.op, this.right, super.position);
}

class CompareExpr extends Expr {
  final Expr left;
  final TokenType op;
  final Expr right;

  const CompareExpr(this.left, this.op, this.right, super.position);
}

class LogicalExpr extends Expr {
  final Expr left;
  final TokenType op;
  final Expr right;

  const LogicalExpr(this.left, this.op, this.right, super.position);
}

class MergeExpr extends Expr {
  final Expr left;
  final TokenType op;
  final Expr right;

  const MergeExpr(this.left, this.op, this.right, super.position);
}

class TernaryExpr extends Expr {
  final Expr condition;
  final Expr thenExpr;
  final Expr elseExpr;

  const TernaryExpr(this.condition, this.thenExpr, this.elseExpr, super.position);
}