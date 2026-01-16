import '../lexer/lexer.dart';
import '../runtime/context.dart';
import '../runtime/values.dart';
import 'dart:math' as Math;

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
  const Expr();
  RuntimeValue eval(EvalContext ctx);
}

class InvalidExpr extends Expr {
  static const instance = InvalidExpr._();
  
  const InvalidExpr._();
  
  @override
  RuntimeValue eval(EvalContext ctx) => InvalidValue.instance;
}

class IntExpr extends Expr {
  final int value;
  IntExpr(this.value);

  @override
  RuntimeValue eval(EvalContext ctx) => IntValue(value);
}

class FloatExpr extends Expr {
  final double value;
  FloatExpr(this.value);

  @override
  RuntimeValue eval(EvalContext ctx) => FloatValue(value);
}

class VarExpr extends Expr {
  final String name;
  VarExpr(this.name);

  @override
  RuntimeValue eval(EvalContext ctx) => ctx.resolve(name);
}

class BinaryExpr extends Expr {
  final Expr left;
  final TokenType op;
  final Expr right;

  BinaryExpr(this.left, this.op, this.right);

  @override
  RuntimeValue eval(EvalContext ctx) {
    final l = left.eval(ctx);
    final r = right.eval(ctx);

    bool intOp = l is IntValue && r is IntValue;

    switch (op) {
      case TokenType.plus:
        if (intOp) return IntValue(l.asInt() + r.asInt());
        return FloatValue(l.asFloat() + r.asFloat());
        
      case TokenType.minus:
        if (intOp) return IntValue(l.asInt() - r.asInt());
        return FloatValue(l.asFloat() - r.asFloat());
        
      case TokenType.star:
        if (intOp) return IntValue(l.asInt() * r.asInt());
        return FloatValue(l.asFloat() * r.asFloat());
        
      case TokenType.slash:
        return FloatValue(l.asFloat() / r.asFloat());
        
      case TokenType.percent:
        if (!intOp) throw FormatException('% only allowed for int32');
        return IntValue(l.asInt() % r.asInt());
        
      case TokenType.intDiv:
        if (!intOp) throw FormatException('IntDiv only allowed for int32');
        return IntValue(l.asInt() ~/ r.asInt());
        
      case TokenType.power:
        if (intOp) return IntValue(Math.pow(l.asInt(), r.asInt()) as int);
        return FloatValue(Math.pow(l.asFloat(), r.asFloat()) as double);


      case TokenType.bitAnd:
        return IntValue(_asInt(l) & _asInt(r));
        
      case TokenType.bitOr:
        return IntValue(_asInt(l) | _asInt(r));
        
      case TokenType.bitXor:
        return IntValue(_asInt(l) ^ _asInt(r));
        
      case TokenType.shiftLeft:
        return IntValue(_asInt(l) << _asInt(r));
        
      case TokenType.shiftRight:
        return IntValue(_asInt(l) >> _asInt(r));
        
      case TokenType.rotLeft:
        return IntValue(_rotl(_asInt(l), _asInt(r)));
        
      case TokenType.rotRight:
        return IntValue(_rotr(_asInt(l), _asInt(r)));

      default:
        throw FormatException('Unsupported binary operator: $op');
    }
  }

  int _asInt(RuntimeValue v) {
    if (v is! IntValue) throw FormatException('Bitwise operation requires int32');
    return v.asInt();
  }

  int _rotl(int v, int n) {
    n &= 31;
    return ((v << n) | (v >> (32 - n))) & 0xffffffff;
  }

  int _rotr(int v, int n) {
    n &= 31;
    return ((v >> n) | (v << (32 - n))) & 0xffffffff;
  }
}

class UnaryExpr extends Expr {
  final TokenType op;
  final Expr expr;

  UnaryExpr(this.op, this.expr);

  @override
  RuntimeValue eval(EvalContext ctx) {
    final v = expr.eval(ctx);

    switch (op) {
      case TokenType.minus:
        if (v is IntValue) return IntValue(-v.asInt());
        return FloatValue(-v.asFloat());
        
      case TokenType.plus:
        return v; // unary + does nothing
        
      case TokenType.bitNot:
        return IntValue(~v.asInt());
        
      default:
        throw FormatException('Unsupported unary operator: $op');
    }
  }
}

class NotExpr extends Expr {
  final Expr expr;

  NotExpr(this.expr);

  @override
  RuntimeValue eval(EvalContext ctx) {
    final v = expr.eval(ctx);
    return IntValue(v.asFloat() == 0 ? 1 : 0);
  }
}

class CompareExpr extends Expr {
  final Expr left;
  final TokenType op;
  final Expr right;

  static const double _eps = 1e-6;

  CompareExpr(this.left, this.op, this.right);

  @override
  RuntimeValue eval(EvalContext ctx) {
    final l = left.eval(ctx);
    final r = right.eval(ctx);

    bool result;

    switch (op) {

      // non-strict
      case TokenType.equalEqual:
        result = l.asFloat() == r.asFloat();
        break;

      case TokenType.notEqual:
        result = l.asFloat() != r.asFloat();
        break;

      // strict
      case TokenType.strictEqual:
        result = l.runtimeType == r.runtimeType &&
                 l.asFloat() == r.asFloat();
        break;

      case TokenType.strictNotEqual:
        result = !(l.runtimeType == r.runtimeType &&
                   l.asFloat() == r.asFloat());
        break;

      // approximate
      case TokenType.approxEqual:
        result = (l.asFloat() - r.asFloat()).abs() <= _eps;
        break;

      case TokenType.notApproxEqual:
        result = (l.asFloat() - r.asFloat()).abs() > _eps;
        break;

      default:
        throw StateError('Invalid comparison operator');
    }

    return IntValue(result ? 1 : 0);
  }
}

class LogicalExpr extends Expr {
  final Expr left;
  final TokenType op;
  final Expr right;

  LogicalExpr(this.left, this.op, this.right);

  @override
  RuntimeValue eval(EvalContext ctx) {
    final l = left.eval(ctx);
    final lt = l.asFloat() != 0;

    switch (op) {
      case TokenType.logicalAnd:
        if (!lt) return IntValue(0);
        return IntValue(right.eval(ctx).asFloat() != 0 ? 1 : 0);

      case TokenType.logicalOr:
        if (lt) return IntValue(1);
        return IntValue(right.eval(ctx).asFloat() != 0 ? 1 : 0);

      case TokenType.logicalXor:
        final rt = right.eval(ctx).asFloat() != 0;
        return IntValue((lt ^ rt) ? 1 : 0);

      default:
        throw StateError('Invalid logical operator');
    }
  }
}

class MergeExpr extends Expr {
  final Expr left;
  final TokenType op;
  final Expr right;

  MergeExpr(this.left, this.op, this.right);

  @override
  RuntimeValue eval(EvalContext ctx) {

    switch (op) {
      case TokenType.coalesce:
        final l = left.eval(ctx);
        if (l.asFloat() != 0) return l;
        return right.eval(ctx);

      case TokenType.guard:
        final r = right.eval(ctx);
        if (r.asFloat() != 0)
          return left.eval(ctx);
        return IntValue(0);

      default:
        throw StateError('Invalid merge operator');
    }
  }
}

class FunctionCallExpr extends Expr {
  final String name;
  final List<Expr> args;

  FunctionCallExpr(this.name, this.args);

  @override
  RuntimeValue eval(EvalContext ctx) {
    final fn = ctx.getFunction(name);
    if (fn == null)
      throw FormatException('Unknown function: $name');

    final evaluatedArgs = args.map((e) => e.eval(ctx)).toList();
    return fn(evaluatedArgs);
  }
}

class TernaryExpr extends Expr {
  final Expr condition;
  final Expr thenExpr;
  final Expr elseExpr;

  TernaryExpr(this.condition, this.thenExpr, this.elseExpr);

  @override
  RuntimeValue eval(EvalContext ctx) {
    final cond = condition.eval(ctx);
    if (cond.asFloat() != 0) {
      return thenExpr.eval(ctx);
    } else {
      return elseExpr.eval(ctx);
    }
  }
}