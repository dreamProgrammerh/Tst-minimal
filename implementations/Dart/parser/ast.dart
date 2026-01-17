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
  final Position position;
  const Expr(this.position);
  RuntimeValue eval(EvalContext ctx);
}

class InvalidExpr extends Expr {
  static const instance = InvalidExpr._((start: -1, length: 0));
  
  const InvalidExpr._(super.position);
  
  @override
  RuntimeValue eval(EvalContext ctx) => InvalidValue.instance;
}

class IntExpr extends Expr {
  final int value;
  const IntExpr(this.value, super.position);

  @override
  RuntimeValue eval(EvalContext ctx) => IntValue(value);
}

class FloatExpr extends Expr {
  final double value;
  const FloatExpr(this.value, super.position);

  @override
  RuntimeValue eval(EvalContext ctx) => FloatValue(value);
}

class VarExpr extends Expr {
  final String name;
  const VarExpr(this.name, super.position);

  @override
  RuntimeValue eval(EvalContext ctx) {
   RuntimeState.pushPosition(position);
   final res = ctx.resolve(name);
   RuntimeState.popPosition();
   return res;
  }
}

class BinaryExpr extends Expr {
  final Expr left;
  final TokenType op;
  final Expr right;

  const BinaryExpr(this.left, this.op, this.right, super.position);

  @override
  RuntimeValue eval(EvalContext ctx) {
    RuntimeState.pushPosition(position);
    final l = left.eval(ctx);
    final r = right.eval(ctx);

    bool intOp = l is IntValue && r is IntValue;
    RuntimeValue res;

    switch (op) {
      case TokenType.plus:
        if (intOp) {
          res = IntValue(l.asInt() + r.asInt());
          break;
        }
        
        res = FloatValue(l.asFloat() + r.asFloat());
        break;
        
      case TokenType.minus:
        if (intOp) {
          res = IntValue(l.asInt() - r.asInt());
          break;
        }
        
        res = FloatValue(l.asFloat() - r.asFloat());
        break;
        
      case TokenType.star:
        if (intOp) {
          res = IntValue(l.asInt() * r.asInt());
          break;
        }
        
        res = FloatValue(l.asFloat() * r.asFloat());
        break;
        
      case TokenType.slash:
        res = FloatValue(l.asFloat() / r.asFloat());
        break;
        
      case TokenType.percent:
        if (intOp) {
          res = IntValue(l.asInt() % r.asInt());
          break;
        }
          
        RuntimeState.error('% only allowed for int32');
        return InvalidValue.instance;
        
      case TokenType.intDiv:
        if (intOp) {
          res = IntValue(l.asInt() ~/ r.asInt());
          break;
        }
          
        RuntimeState.error('IntDiv only allowed for int32');
        res = InvalidValue.instance;
        break;
        
        
      case TokenType.power:
        if (intOp) {
          res = IntValue(Math.pow(l.asInt(), r.asInt()) as int);
          break;
        }
        
        res = FloatValue(Math.pow(l.asFloat(), r.asFloat()) as double);
        break;


      case TokenType.bitAnd:
        res = IntValue(_asInt(l) & _asInt(r));
        break;
        
      case TokenType.bitOr:
        res = IntValue(_asInt(l) | _asInt(r));
        break;
        
      case TokenType.bitXor:
        res = IntValue(_asInt(l) ^ _asInt(r));
        break;
        
      case TokenType.shiftLeft:
        res = IntValue(_asInt(l) << _asInt(r));
        break;
        
      case TokenType.shiftRight:
        res = IntValue(_asInt(l) >> _asInt(r));
        break;
        
      case TokenType.rotLeft:
        res = IntValue(_rotl(_asInt(l), _asInt(r)));
        break;
        
      case TokenType.rotRight:
        res = IntValue(_rotr(_asInt(l), _asInt(r)));
        break;

      default:
        RuntimeState.error('Unsupported binary operator: $op');
        res = InvalidValue.instance;
        break;
    }
    
    RuntimeState.popPosition();
    return res;
  }

  int _asInt(RuntimeValue v) {
    if (v is IntValue) 
      return v.asInt();
    
    RuntimeState.error('Bitwise operation requires int32');
    return 0;
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

  const UnaryExpr(this.op, this.expr, super.position);

  @override
  RuntimeValue eval(EvalContext ctx) {
    RuntimeState.pushPosition(position);
    final v = expr.eval(ctx);
    RuntimeValue res;

    switch (op) {
      case TokenType.minus:
        if (v is IntValue) return IntValue(-v.asInt());
        res = FloatValue(-v.asFloat());
        break;
        
      case TokenType.plus:
        res = v; // unary + does nothing
        break;
        
      case TokenType.bitNot:
        res = IntValue(~v.asInt());
        break;
        
      default:
        RuntimeState.error('Unsupported unary operator: $op');
        res = InvalidValue.instance;
        break;
    }
    
    RuntimeState.popPosition();
    return res;
  }
}

class NotExpr extends Expr {
  final Expr expr;

  const NotExpr(this.expr, super.position);

  @override
  RuntimeValue eval(EvalContext ctx) {
    RuntimeState.pushPosition(position);
    final v = expr.eval(ctx);
    final res = IntValue(v.asFloat() == 0 ? 1 : 0);
    RuntimeState.popPosition();
    
    return res;
  }
}

class CompareExpr extends Expr {
  final Expr left;
  final TokenType op;
  final Expr right;

  static const double _eps = 1e-6;

  const CompareExpr(this.left, this.op, this.right, super.position);

  @override
  RuntimeValue eval(EvalContext ctx) {
    RuntimeState.pushPosition(position);
    final l = left.eval(ctx);
    final r = right.eval(ctx);

    RuntimeValue? res;
    bool result = false;

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
        
      case TokenType.less:
        result = l.asFloat() < r.asFloat();
        break;
      
      case TokenType.greater:
        result = l.asFloat() > r.asFloat();
        break;
      
      case TokenType.lessEqual:
        result = l.asFloat() <= r.asFloat();
        break;
      
      case TokenType.greaterEqual:
        result = l.asFloat() >= r.asFloat();
        break;

      default:
        RuntimeState.error('Unsupported comparison operator: $op');
        res = InvalidValue.instance;
        break;
    }

    RuntimeState.popPosition();
    return res ?? IntValue(result ? 1 : 0);
  }
}

class LogicalExpr extends Expr {
  final Expr left;
  final TokenType op;
  final Expr right;

  const LogicalExpr(this.left, this.op, this.right, super.position);

  @override
  RuntimeValue eval(EvalContext ctx) {
    RuntimeState.pushPosition(position);
    final l = left.eval(ctx);
    final lt = l.asFloat() != 0;
    
    RuntimeValue res;

    switch (op) {
      case TokenType.logicalAnd:
        if (!lt) {
          res = IntValue(0);
          break;
        }
        
        res = IntValue(right.eval(ctx).asFloat() != 0 ? 1 : 0);
        break;

      case TokenType.logicalOr:
        if (lt) {
          res = IntValue(1);
          break;
        }
        
        res = IntValue(right.eval(ctx).asFloat() != 0 ? 1 : 0);
        break;

      case TokenType.logicalXor:
        final rt = right.eval(ctx).asFloat() != 0;
        res = IntValue((lt ^ rt) ? 1 : 0);
        break;

      default:
        RuntimeState.error('Invalid logical operator');
        res = InvalidValue.instance;
    }
    
    RuntimeState.popPosition();
    return res;
  }
}

class MergeExpr extends Expr {
  final Expr left;
  final TokenType op;
  final Expr right;

  const MergeExpr(this.left, this.op, this.right, super.position);

  @override
  RuntimeValue eval(EvalContext ctx) {
    RuntimeState.pushPosition(position);
    
    RuntimeValue res;
    
    switch (op) {
      case TokenType.coalesce:
        final l = left.eval(ctx);
        res = l.asFloat() != 0
          ? l
          : right.eval(ctx);
        break;
          
      case TokenType.guard:
        final r = right.eval(ctx);
        res = r.asFloat() != 0
          ? left.eval(ctx)
          : IntValue(0);
        break;

      default:
        RuntimeState.error('Invalid merge operator');
        res = InvalidValue.instance;
    }
    
    RuntimeState.popPosition();
    return res;
  }
}

class FunctionCallExpr extends Expr {
  final String name;
  final List<Expr> args;

  const FunctionCallExpr(this.name, this.args, super.position);

  @override
  RuntimeValue eval(EvalContext ctx) {
    RuntimeState.pushPosition(position);
    
    RuntimeValue res;
    
    final fn = ctx.getFunction(name);
    if (fn == null) {
      RuntimeState.error('Unknown function: $name');
      res = InvalidValue.instance;
      
    } else {
      final evaluatedArgs = args.map((e) => e.eval(ctx)).toList();
      res = fn(evaluatedArgs);
    }

    RuntimeState.popPosition();
    return res;
  }
}

class TernaryExpr extends Expr {
  final Expr condition;
  final Expr thenExpr;
  final Expr elseExpr;

  const TernaryExpr(this.condition, this.thenExpr, this.elseExpr, super.position);

  @override
  RuntimeValue eval(EvalContext ctx) {
    RuntimeState.pushPosition(position);
    
    final cond = condition.eval(ctx);
    RuntimeValue res = cond.asFloat() != 0
      ? thenExpr.eval(ctx)
      : elseExpr.eval(ctx);
    
    RuntimeState.popPosition();
    return res;
  }
}