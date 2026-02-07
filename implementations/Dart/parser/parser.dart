import '../error/errors.dart';
import '../error/reporter.dart';
import '../lexer/lexer.dart';
import '../lexer/source.dart';
import '../runtime/values.dart';
import 'ast.dart';

class Parser {
  final ErrorReporter reporter;
  final List<Token> tokens;
  final Source? source;
  int _pos = 0;

  Parser(this.tokens, {required this.reporter, this.source});

  Token get _current => _pos < tokens.length
    ? tokens[_pos] : tokens[tokens.length - 1];

  Token get _prev =>
    0 <= _pos - 1 && _pos - 1 < tokens.length
      ? tokens[_pos - 1]
      : tokens[0];

  bool get _isAtEnd => _current.type == TokenType.eof;

  Position _p(int start) => (start: start, length: _prev.end - start);

  List<Expr> interpret(List<Token> tokens) {
    final I = _pos;
    _pos = this.tokens.length;
    // add new tokens at end
    this.tokens.addAll(tokens);

    final expressions = <Expr>[];
    while (!_isAtEnd) {
      final expr = _expression();
      expressions.add(expr);
    }


    // remove new tokens from end
    this.tokens.removeRange(this.tokens.length - tokens.length, this.tokens.length - 1);
    _pos = I;
    return expressions;
  }

  Program parse() {
    _pos = 0;
    List<Declaration> declarations = [];

    while (!_isAtEnd) {
      final decl = _parseDecl();

      if (decl == null)
        break;

      declarations.add(decl);
    }

    return Program(declarations);
  }

  Declaration? _parseDecl() {
    final start = _current.start;

    String? name = null;
    if (_is(TokenType.identifier))
      name = _advance().lexeme;

    if (_expect(TokenType.colon,
      "Expected ':'"))
      return null;

    Expr expr = _expression();

    if (expr == InvalidExpr.instance)
      return null;

    return Declaration(name, expr, _p(start));
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
   * primary (int, float, variable, literal, call, parenthesized)
   */


  Expr _expression() {
    final expr = _inlineDecl();
    _ignoreSemicolons();
    return expr;
  }

  Expr _inlineDecl() {
    if (!(_is(TokenType.identifier) && _peek(1).type == TokenType.colon))
      return _ternary();

    final start = _current.start;
    final name = _advance().lexeme;
    _advance(); // colon

    final expr = _expression();

    return InlineDeclExpr(name, expr, _p(start));
  }

  Expr _ternary() {
    final start = _current.start;
    final condition = _merge();

    if (_match(TokenType.question)) {
      final thenExpr = _ternary();

      if (_expect(TokenType.colon,
        "Expected ':' in ternary expression"))
        return InvalidExpr.instance;

      final elseExpr = _ternary();
      return TernaryExpr(condition, thenExpr, elseExpr, _p(start));
    }

    return condition;
  }

  Expr _merge() {
    final start = _current.start;
    var expr = _or();

    loop:
    while (true) {
      final type = _current.type;
      switch (type) {
        case TokenType.coalesce:
        case TokenType.guard:
          _advance();
          expr = MergeExpr(expr, type, _or(), _p(start));
          break;

        default:
          break loop;
      }
    }

    return expr;
  }

  Expr _or() {
    final start = _current.start;
    var expr = _xor();
    while (_match(TokenType.logicalOr))
      expr = LogicalExpr(expr, TokenType.logicalOr, _xor(), _p(start));

    return expr;
  }

  Expr _xor() {
    final start = _current.start;
    var expr = _and();
    while (_match(TokenType.logicalXor))
      expr = LogicalExpr(expr, TokenType.logicalXor, _and(), _p(start));

    return expr;
  }

  Expr _and() {
    final start = _current.start;
    var expr = _equality();
    while (_match(TokenType.logicalAnd))
      expr = LogicalExpr(expr, TokenType.logicalAnd, _equality(), _p(start));

    return expr;
  }


  Expr _equality() {
    final start = _current.start;
    var expr = _comparison();

    loop:
    while (true) {
      final type = _current.type;
      switch (type) {
        case TokenType.equalEqual:
        case TokenType.notEqual:
        case TokenType.approxEqual:
        case TokenType.notApproxEqual:
        case TokenType.strictEqual:
        case TokenType.strictNotEqual:
          _advance();
          expr = CompareExpr(expr, type, _comparison(), _p(start));
          break;

        default:
          break loop;
      }
    }

    return expr;
  }

  Expr _comparison() {
    final start = _current.start;
    var expr = _bitOr();

    loop:
    while (true) {
      final type = _current.type;
      switch (type) {
        case TokenType.less:
        case TokenType.greater:
        case TokenType.lessEqual:
        case TokenType.greaterEqual:
          _advance();
          expr = CompareExpr(expr, type, _bitOr(), _p(start));
          break;

        default:
          break loop;
      }
    }

    return expr;
  }

  Expr _bitOr() {
    final start = _current.start;
    var expr = _bitXor();
    while (_match(TokenType.bitOr))
      expr = BinaryExpr(expr, TokenType.bitOr, _bitXor(), _p(start));

    return expr;
  }

  Expr _bitXor() {
    final start = _current.start;
    var expr = _bitAnd();
    while (_match(TokenType.bitXor))
      expr = BinaryExpr(expr, TokenType.bitXor, _bitAnd(), _p(start));

    return expr;
  }

  Expr _bitAnd() {
    final start = _current.start;
    var expr = _shift();
    while (_match(TokenType.bitAnd))
      expr = BinaryExpr(expr, TokenType.bitAnd, _shift(), _p(start));

    return expr;
  }

  Expr _shift() {
    final start = _current.start;
    var expr = _additive();

    loop:
    while (true) {
      final type = _current.type;
      switch (type) {
        case TokenType.shiftLeft:
        case TokenType.shiftRight:
        case TokenType.rotLeft:
        case TokenType.rotRight:
          _advance();
          expr = BinaryExpr(expr, type, _additive(), _p(start));
          break;

        default:
          break loop;
      }
    }

    return expr;
  }

  Expr _additive() {
    final start = _current.start;
    var expr = _term();

    loop:
    while (true) {
      final type = _current.type;
      switch (type) {
        case TokenType.plus:
        case TokenType.minus:
          _advance();
          expr = BinaryExpr(expr, type, _term(), _p(start));
          break;

        default:
          break loop;
      }
    }

    return expr;
  }

  Expr _term() {
    final start = _current.start;
    var expr = _power();

    loop:
    while (true) {
      final type = _current.type;
      switch (type) {
        case TokenType.star:
        case TokenType.slash:
        case TokenType.percent:
        case TokenType.intDiv:
          _advance();
          expr = BinaryExpr(expr, type, _power(), _p(start));
          break;

        default:
          break loop;
      }
    }

    return expr;
  }

  Expr _power() {
    final start = _current.start;
    var expr = _unary();
    if (_match(TokenType.power))
      expr = BinaryExpr(expr, TokenType.power, _power(), _p(start));

    return expr;
  }

  Expr _unary() {
    final start = _current.start;
    final type = _current.type;
    switch (type) {
      case TokenType.not:
        _advance();
        return NotExpr(_unary(), _p(start));

      case TokenType.minus:
      case TokenType.plus:
      case TokenType.bitNot:
        _advance();
        return UnaryExpr(type, _unary(), _p(start));

      default:
        return _primary();
    }
  }

  Expr _primary() {
    final start = _current.start;
    final cur = _advance();

    switch (cur.type) {
      case TokenType.int32:
      case TokenType.hexColor:
      case TokenType.hex:
      case TokenType.oct:
      case TokenType.bin:
        int? value = cur.asInt();
        return value != null
          ? IntExpr(value, _p(start))
          : InvalidExpr.instance;

      case TokenType.float32:
        double? value = cur.asFloat();
        return value != null
          ? FloatExpr(value, _p(start))
          : InvalidExpr.instance;

      case TokenType.dollar:
        if (_expect(TokenType.identifier,
          "Expected identifier after \$"))
          return InvalidExpr.instance;


        final name = _peek(-1).lexeme;
        return VarExpr(name, _p(start));

      case TokenType.identifier:
        final name = cur.lexeme;

        if (!_match(TokenType.lParen)) {
          return LiteralExpr(name, _p(start));
        }

        final args = <Expr>[];
        if (!_match(TokenType.rParen)) {
          do {
            if (_is(TokenType.rParen)) break;
            args.add(_expression());

          } while (_match(TokenType.comma));

          if (_expect(TokenType.rParen,
            "Expected ')' after function arguments"))
            return InvalidExpr.instance;
        }

        return CallExpr(name, args, _p(start));

      case TokenType.lParen:
        final expr = _expression();
        if (_expect(TokenType.rParen,
          "Expected ')'"))
          return InvalidExpr.instance;

        return expr;

      default:
        _error("Unexpected token: '${cur.lexeme}'", cur.start, cur.len);
        return InvalidExpr.instance;
    }

  }

  void _ignoreSemicolons() {
    while (_is(TokenType.semicolon)) _pos++;
  }

  bool _error(String msg, [int start = -1, int len = 1]) {
    return reporter.push(ParserError(msg, start, len), source: source);
  }

  Token _advance() {
    final c = _current;
    if (!_isAtEnd)
      _pos++;

    return c;
  }

  Token _peek([int index = 0]) {
    final newPos = _pos + index;

    if (0 <= newPos && newPos < tokens.length)
      return tokens[newPos];

    return Token.INVALID;
  }

  bool _is(TokenType type) => _current.type == type;

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

    _error(msg, _current.start, _current.len);
    return true;
  }
}
