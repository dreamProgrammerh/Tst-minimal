import 'dart:math' as Math;

import '../constants/const-eval.dart' as EVAL;
import '../error/reporter.dart';
import '../lexer/lexer.dart';
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
    final ctx = EvalContext(program);
    
    EvalMap map = {};
    
    for (final decl in program.declarations) {
      final value = evaluate(decl.expr, ctx);
      map[decl.name] = value;
    }
    
    return map;
  }
  
  static RuntimeValue evaluate(Expr expression, EvalContext ctx) {
    RuntimeState.pushPosition(expression.position);
    RuntimeValue res;
    
    switch (expression) {
      case InvalidExpr _:
       res = InvalidValue.instance;
       break;
      
      case IntExpr intExpr:
       res = IntValue(intExpr.value);
       break;
      
      case FloatExpr floatExpr:
        res = FloatValue(floatExpr.value);
        break;
        
      case VarExpr varExpr:
        res = ctx.resolve(varExpr.name);
        break;
        
      case LiteralExpr literalExpr:
        res = _evalLiteral(literalExpr, ctx);
        break;
        
      case CallExpr callExpr:
        res = _evalCall(callExpr, ctx);
        break;
        
      case NotExpr notExpr:
        final v = Evaluator.evaluate(notExpr.expr, ctx);
        res = IntValue(v.asFloat() == 0 ? 1 : 0);
        break;
      
      case UnaryExpr unaryExpr:
        res = _evalUnaryOp(unaryExpr, ctx);
        break;
      
      case BinaryExpr binaryExpr:
        res = _evalBinaryOp(binaryExpr, ctx);
        break;
      
      case CompareExpr compareExpr:
        res = _evalCompareOp(compareExpr, ctx);
        break;
      
      case LogicalExpr logicalExpr:
        res = _evalLogicalOp(logicalExpr, ctx);
        break;
      
      case MergeExpr mergeExpr:
        res = _evalMergeOp(mergeExpr, ctx);
        break;
      
      case TernaryExpr ternaryExpr:
        res = _evalTernaryOp(ternaryExpr, ctx);
        break;
      
      default:
        RuntimeState.error("Invalid expression: ${expression.runtimeType}");
        res = InvalidValue.instance;
    }
    
    RuntimeState.popPosition();
    return res;
  }
}

// Helpers
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

// Eval Functions
RuntimeValue _evalLiteral(LiteralExpr e, EvalContext ctx) {
  RuntimeValue res;
  
  final lit = ctx.getLiteral(e.literal);
  if (lit == null) {
    RuntimeState.error('Unknown literal: ${e.literal}');
    res = InvalidValue.instance;
  } else {
    res = lit;
  }

  return res;
}
RuntimeValue _evalCall(CallExpr e, EvalContext ctx) {
  RuntimeValue res;
  
  final fn = ctx.getFunction(e.name);
  if (fn == null) {
    RuntimeState.error('Unknown function: ${e.name}');
    res = InvalidValue.instance;
  } else {
    final evaluatedArgs = e.args.map(
      (e) => Evaluator.evaluate(e, ctx)
    ).toList();
    res = fn(evaluatedArgs);
  }

  return res;
}

RuntimeValue _evalUnaryOp(UnaryExpr e, EvalContext ctx) {
  final v = Evaluator.evaluate(e.expr, ctx);
  RuntimeValue res;

  switch (e.op) {
    case TokenType.minus:
      if (v is IntValue) return IntValue(-v.asInt());
      res = FloatValue(-v.asFloat());
      break;
      
    case TokenType.plus:
      res = v; // unary '+' does nothing
      break;
      
    case TokenType.bitNot:
      res = IntValue(~v.asInt());
      break;
    
    default:
      RuntimeState.error('Unsupported unary operator: ${e.op}');
      res = InvalidValue.instance;
      break;
  }
  
  return res;
}

RuntimeValue _evalBinaryOp(BinaryExpr e, EvalContext ctx) {
  final l = Evaluator.evaluate(e.left,  ctx);
  final r = Evaluator.evaluate(e.right, ctx);

  bool intOp = l is IntValue && r is IntValue;
  RuntimeValue res;

  switch (e.op) {
    case TokenType.plus:
      res = intOp
        ? IntValue(l.asInt() + r.asInt())
        : FloatValue(l.asFloat() + r.asFloat());
      break;
      
    case TokenType.minus:
      res = intOp
        ? IntValue(l.asInt() - r.asInt())
        : FloatValue(l.asFloat() - r.asFloat());
      break;
      
    case TokenType.star:
      res = intOp
        ? IntValue(l.asInt() * r.asInt())
        : FloatValue(l.asFloat() * r.asFloat());
      break;
      
    case TokenType.slash:
      res = FloatValue(l.asFloat() / r.asFloat());
      break;
      
    case TokenType.percent:
      if (!intOp) {
        RuntimeState.error('% only allowed for intgers');
        res = InvalidValue.instance;
        break;
      }
        
      res = IntValue(l.asInt() % r.asInt());
      break;
      
    case TokenType.intDiv:
      res = IntValue(l.asInt() ~/ r.asInt());
      break;
       
    case TokenType.power:
      res = intOp
        ? IntValue(Math.pow(l.asInt(), r.asInt()) as int)
        : FloatValue(Math.pow(l.asFloat(), r.asFloat()) as double);
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
      RuntimeState.error('Unsupported binary operator: ${e.op}');
      res = InvalidValue.instance;
      break;
  }
  
  return res;
}

RuntimeValue _evalCompareOp(CompareExpr e, EvalContext ctx) {
  final l = Evaluator.evaluate(e.left, ctx);
  final r = Evaluator.evaluate(e.right, ctx);

  RuntimeValue? res;
  bool result = false;

  switch (e.op) {
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
      result = (l.asFloat() - r.asFloat()).abs() <= EVAL.eps;
      break;

    case TokenType.notApproxEqual:
      result = (l.asFloat() - r.asFloat()).abs() > EVAL.eps;
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
      RuntimeState.error('Unsupported comparison operator: ${e.op}');
      res = InvalidValue.instance;
      break;
  }

  return res ?? IntValue(result ? 1 : 0);
}

RuntimeValue _evalLogicalOp(LogicalExpr e, EvalContext ctx) {
  final l = Evaluator.evaluate(e.left, ctx);
  final lt = l.asFloat() != 0;
  
  RuntimeValue res;

  switch (e.op) {
    case TokenType.logicalAnd:
      if (!lt) {
        res = IntValue(0);
        break;
      }
      
      final r = Evaluator.evaluate(e.right, ctx);
      res = IntValue(r.asFloat() != 0 ? 1 : 0);
      break;

    case TokenType.logicalOr:
      if (lt) {
        res = IntValue(1);
        break;
      }
      
      final r = Evaluator.evaluate(e.right, ctx);
      res = IntValue(r.asFloat() != 0 ? 1 : 0);
      break;

    case TokenType.logicalXor:
      final r = Evaluator.evaluate(e.right, ctx);
      final rt = r.asFloat() != 0;
      res = IntValue((lt ^ rt) ? 1 : 0);
      break;

    default:
      RuntimeState.error('Invalid logical operator');
      res = InvalidValue.instance;
  }
  
  return res;
}

RuntimeValue _evalMergeOp(MergeExpr e, EvalContext ctx) {
  RuntimeValue res;
  
  switch (e.op) {
    case TokenType.coalesce:
      final l = Evaluator.evaluate(e.left, ctx);
      res = l.asFloat() != 0
        ? l
        : Evaluator.evaluate(e.right, ctx);
      break;
        
    case TokenType.guard:
      final r = Evaluator.evaluate(e.right, ctx);
      res = r.asFloat() != 0
        ? Evaluator.evaluate(e.left, ctx)
        : IntValue(0);
      break;

    default:
      RuntimeState.error('Invalid merge operator');
      res = InvalidValue.instance;
  }
  
  return res;
}

RuntimeValue _evalTernaryOp(TernaryExpr e, EvalContext ctx) {
  final cond = Evaluator.evaluate(e.condition, ctx);
  Expr target = cond.asFloat() != 0
    ? e.thenExpr
    : e.elseExpr;
  
  return Evaluator.evaluate(target, ctx);
}
