import '../error/errors.dart';
import '../error/reporter.dart';
import '../lexer/lexer.dart';
import '../lexer/source.dart';
import 'ast.dart';

class Parser {
  final ErrorReporter reporter;
  final List<Token> tokens;
  final Source? source;
  int pos = 0;

  Parser(this.tokens, {required this.reporter, this.source});

  Token get current => pos < tokens.length
    ? tokens[pos] : tokens[tokens.length - 1];
  bool get isAtEnd => current.type == TokenType.eof;

  Program parse() {
    List<Declaration> declarations = [];

    while (!isAtEnd) {
      final decl = parseDecl();

      if (decl == null)
        break;

      declarations.add(decl);
    }

    return Program(declarations);
  }

  Declaration? parseDecl() {
    int start = current.start;

    if (_expect(TokenType.identifier,
      "Expected identifier for declration"))
      return null;

    String name = _peek(-1).lexeme;

    if (_expect(TokenType.colon,
      "Expected ':'"))
      return null;

    Expr expr = _expression();

    if (expr == InvalidExpr.instance)
      return null;

    return Declaration(name, expr,
      (start: start, length: current.start - start));
  }

  // Expression hierarchy
  /*
   * Expression
   * ternary (a ? b : c)
   * merge (coalesce ??, guard !!)
   * logical (or ||, xor ^^, and &&)
   * equality (==, !=, ~=, !~=, ===, !==)
   * comparison (<, >, <=, >=)
   * bitwise (or |, xor ^, and &)
   * bitshift (left <<, right >>, rotleft <<<, rotright >>>)
   * additive (+, -)
   * term (*, /, %, /%)
   * power (**)
   * unary (not !, negatives -, positive +, flip not ~)
   * primary (int, float, variable, call, parenthesized)
   */


  Expr _expression() => _ternary();

  Expr _ternary() {
    int start = current.start;
    var condition = _merge();

    if (_match(TokenType.question)) {
      final thenExpr = _ternary();

      if (_expect(TokenType.colon,
        "Expected ':' in ternary expression"))
        return InvalidExpr.instance;

      final elseExpr = _ternary();
      return TernaryExpr(condition, thenExpr, elseExpr,
        (start: start, length: current.start - start));
    }

    return condition;
  }

  Expr _merge() {
    int start = current.start;
    var expr = _or();

    loop:
    while (true) {
      final type = current.type;
      switch (type) {
        case TokenType.coalesce:
        case TokenType.guard:
          _advance();
          expr = MergeExpr(expr, type, _or(),
            (start: start, length: current.start - start));
          break;

        default:
          break loop;
      }
    }

    return expr;
  }

  Expr _or() {
    int start = current.start;
    var expr = _xor();
    while (_match(TokenType.logicalOr))
      expr = LogicalExpr(expr, TokenType.logicalOr, _xor(),
        (start: start, length: current.start - start));

    return expr;
  }

  Expr _xor() {
    int start = current.start;
    var expr = _and();
    while (_match(TokenType.logicalXor))
      expr = LogicalExpr(expr, TokenType.logicalXor, _and(),
        (start: start, length: current.start - start));

    return expr;
  }

  Expr _and() {
    int start = current.start;
    var expr = _equality();
    while (_match(TokenType.logicalAnd))
      expr = LogicalExpr(expr, TokenType.logicalAnd, _equality(),
        (start: start, length: current.start - start));

    return expr;
  }


  Expr _equality() {
    int start = current.start;
    var expr = _comparison();

    loop:
    while (true) {
      final type = current.type;
      switch (type) {
        case TokenType.equalEqual:
        case TokenType.notEqual:
        case TokenType.approxEqual:
        case TokenType.notApproxEqual:
        case TokenType.strictEqual:
        case TokenType.strictNotEqual:
          _advance();
          expr = CompareExpr(expr, type, _comparison(),
            (start: start, length: current.start - start));
          break;

        default:
          break loop;
      }
    }

    return expr;
  }

  Expr _comparison() {
    int start = current.start;
    var expr = _bitOr();

    loop:
    while (true) {
      final type = current.type;
      switch (type) {
        case TokenType.less:
        case TokenType.greater:
        case TokenType.lessEqual:
        case TokenType.greaterEqual:
          _advance();
          expr = CompareExpr(expr, type, _bitOr(),
            (start: start, length: current.start - start));
          break;

        default:
          break loop;
      }
    }

    return expr;
  }

  Expr _bitOr() {
    int start = current.start;
    var expr = _bitXor();
    while (_match(TokenType.bitOr))
      expr = BinaryExpr(expr, TokenType.bitOr, _bitXor(),
        (start: start, length: current.start - start));

    return expr;
  }

  Expr _bitXor() {
    int start = current.start;
    var expr = _bitAnd();
    while (_match(TokenType.bitXor))
      expr = BinaryExpr(expr, TokenType.bitXor, _bitAnd(),
        (start: start, length: current.start - start));

    return expr;
  }

  Expr _bitAnd() {
    int start = current.start;
    var expr = _shift();
    while (_match(TokenType.bitAnd))
      expr = BinaryExpr(expr, TokenType.bitAnd, _shift(),
        (start: start, length: current.start - start));

    return expr;
  }

  Expr _shift() {
    int start = current.start;
    var expr = _additive();

    loop:
    while (true) {
      final type = current.type;
      switch (type) {
        case TokenType.shiftLeft:
        case TokenType.shiftRight:
        case TokenType.rotLeft:
        case TokenType.rotRight:
          _advance();
          expr = BinaryExpr(expr, type, _additive(),
            (start: start, length: current.start - start));
          break;

        default:
          break loop;
      }
    }

    return expr;
  }

  Expr _additive() {
    int start = current.start;
    var expr = _term();

    loop:
    while (true) {
      final type = current.type;
      switch (type) {
        case TokenType.plus:
        case TokenType.minus:
          _advance();
          expr = BinaryExpr(expr, type, _term(),
            (start: start, length: current.start - start));
          break;

        default:
          break loop;
      }
    }

    return expr;
  }

  Expr _term() {
    int start = current.start;
    var expr = _power();

    loop:
    while (true) {
      final type = current.type;
      switch (type) {
        case TokenType.star:
        case TokenType.slash:
        case TokenType.percent:
        case TokenType.intDiv:
          _advance();
          expr = BinaryExpr(expr, type, _power(),
            (start: start, length: current.start - start));
          break;

        default:
          break loop;
      }
    }

    return expr;
  }

  Expr _power() {
    int start = current.start;
    var expr = _unary();
    if (_match(TokenType.power))
      expr = BinaryExpr(expr, TokenType.power, _power(),
        (start: start, length: current.start - start));

    return expr;
  }

  Expr _unary() {
    int start = current.start;
    final type = current.type;
    switch (type) {
      case TokenType.not:
        _advance();
        return NotExpr(_unary(),
          (start: start, length: current.start - start));

      case TokenType.minus:
      case TokenType.plus:
      case TokenType.bitNot:
        _advance();
        return UnaryExpr(type, _unary(),
          (start: start, length: current.start - start));

      default:
        return _primary();
    }
  }

  Expr _primary() {
    int start = current.start;
    final cur = _advance();

    switch (cur.type) {
      case TokenType.int32:
      case TokenType.hexColor:
      case TokenType.hex:
      case TokenType.oct:
      case TokenType.bin:
        int? value = cur.asInt();
        return value != null
          ? IntExpr(value,
            (start: start, length: current.start - start))
          : InvalidExpr.instance;

      case TokenType.float32:
        double? value = cur.asFloat();
        return value != null
          ? FloatExpr(value,
            (start: start, length: current.start - start))
          : InvalidExpr.instance;

      case TokenType.dollar:
        if (_expect(TokenType.identifier,
          "Expected identifier after \$"))
          return InvalidExpr.instance;


        final name = _peek(-1).lexeme;
        return VarExpr(name,
          (start: start, length: current.start - start));

      case TokenType.identifier:
        final name = cur.lexeme;

        if (_expect(TokenType.lParen,
          "Unexpected identifier without function call: $name"))
          return InvalidExpr.instance;

        final args = <Expr>[];
        if (!_match(TokenType.rParen)) {
          do {
            args.add(_expression());

          } while (_match(TokenType.comma));

          if (_expect(TokenType.rParen,
            "Expected ')' after function arguments"))
            return InvalidExpr.instance;
        }

        return FunctionCallExpr(name, args,
          (start: start, length: current.start - start));

      case TokenType.lParen:
        final expr = _expression();
        if (_expect(TokenType.rParen,
          "Expected ')'"))
          return InvalidExpr.instance;

        return expr;

      default:
        _error("Unexpected token: ${current.lexeme}");
        return InvalidExpr.instance;
    }

  }

  bool _error(String msg, [int start = -1, int len = 1]) {
    return reporter.push(ParserError(msg, start, len), source: source);
  }

  Token _advance() {
    final c = current;
    if (!isAtEnd)
      pos++;

    return c;
  }

  Token _peek([int index = 0]) {
    final newPos = pos + index;

    if (0 <= newPos && newPos < tokens.length)
      return tokens[newPos];

    return Token.INVALID;
  }

  bool _is(TokenType type) => current.type == type;

  bool _match(TokenType type) {
    if (_is(type)) {
      _advance();
      return true;
    }
    return false;
  }

  bool _expect(TokenType type, String msg) {
    if (_match(type))
      return false;

    _error(msg, current.start, current.len);
    return true;
  }
}
