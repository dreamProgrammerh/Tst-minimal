import '../constants/const-lexer.dart' as LEXER;
import '../error/errors.dart';
import '../error/reporter.dart';
import '../utils/colors.dart' as Colors show hexColor;
import 'source.dart';

enum TokenType {
  int32, float32, hex, bin, oct,
  hexColor, identifier, dollar,

  plus, minus, star, slash, percent, intDiv, power,
  bitAnd, bitOr, bitXor, bitNot,
  shiftLeft, shiftRight, rotLeft, rotRight,
  question, colon, semicolon,

  not, equalEqual, notEqual,
  strictEqual, strictNotEqual, approxEqual, notApproxEqual,
  less, greater, lessEqual, greaterEqual,

  logicalAnd, logicalOr, logicalXor,
  coalesce, guard,

  lParen, rParen, comma,
  invalid, eof;
}

class Token {
  static const Token INVALID = Token(TokenType.invalid, '', -1);
  
  final TokenType type;
  final String lexeme;
  final int start;

  int get len => lexeme.length;
  int get end => start + lexeme.length;

  const Token(this.type, this.lexeme, this.start);
  

  int? asInt() {
    switch (type) {
      case TokenType.int32:
        return int.parse(lexeme);
        
      case TokenType.hexColor:
        return Colors.hexColor(lexeme);
        
      case TokenType.hex:
        return int.parse(lexeme.substring(2), radix: 16);
        
      case TokenType.oct:
        return int.parse(lexeme.substring(2), radix: 8);
        
      case TokenType.bin:
        return int.parse(lexeme.substring(2), radix: 2);
      
      default:
        return null;
    }
    
  }
  
  double? asFloat() =>
    type == TokenType.float32 ? double.parse(lexeme) : null;
  
  @override
  String toString() => '${type.name}($lexeme)';
}

// Mapping each operator to it type
typedef OperatorNode = (String op, TokenType type);
final List<OperatorNode> _operatorMap = [
  (LEXER.Dollar,          TokenType.dollar),
  (LEXER.Plus,            TokenType.plus),
  (LEXER.Minus,           TokenType.minus),
  (LEXER.Star,            TokenType.star),
  (LEXER.Slash,           TokenType.slash),
  (LEXER.Percent,         TokenType.percent),
  (LEXER.IntDiv,          TokenType.intDiv),
  (LEXER.Power,           TokenType.power),
  (LEXER.BitAnd,          TokenType.bitAnd),
  (LEXER.BitOr,           TokenType.bitOr),
  (LEXER.BitXor,          TokenType.bitXor),
  (LEXER.BitNot,          TokenType.bitNot),
  (LEXER.ShiftLeft,       TokenType.shiftLeft),
  (LEXER.ShiftRight,      TokenType.shiftRight),
  (LEXER.RotateLeft,      TokenType.rotLeft),
  (LEXER.RotateRight,     TokenType.rotRight),
  (LEXER.Question,        TokenType.question),
  (LEXER.Colon,           TokenType.colon),
  (LEXER.Semicolon,       TokenType.semicolon),
  (LEXER.Not,             TokenType.not),
  (LEXER.EqualEqual,      TokenType.equalEqual),
  (LEXER.NotEqual,        TokenType.notEqual),
  (LEXER.StrictEqual,     TokenType.strictEqual),
  (LEXER.StrictNotEqual,  TokenType.strictNotEqual),
  (LEXER.ApproxEqual,     TokenType.approxEqual),
  (LEXER.NotApproxEqual,  TokenType.notApproxEqual),
  (LEXER.Less,            TokenType.less),
  (LEXER.Greater,         TokenType.greater),
  (LEXER.LessEqual,       TokenType.lessEqual),
  (LEXER.GreaterEqual,    TokenType.greaterEqual),
  (LEXER.LogicalAnd,      TokenType.logicalAnd),
  (LEXER.LogicalOr,       TokenType.logicalOr),
  (LEXER.LogicalXor,      TokenType.logicalXor),
  (LEXER.Coalesce,        TokenType.coalesce),
  (LEXER.Guard,           TokenType.guard),
  (LEXER.LParen,          TokenType.lParen),
  (LEXER.RParen,          TokenType.rParen),
  (LEXER.Comma,           TokenType.comma),
]..sort((a, b) => b.$1.length - a.$1.length);


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//             LEXER
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class Lexer {
  final ErrorReporter reporter;
  final Source source;
  String? _extraSource = null;
  int _pos = 0;
  
  String get _src => (_extraSource ?? source.src);
  bool get _isAtEnd => _pos >= _src.length;
  String get _current => _isAtEnd ? '' : _src[_pos];

  Lexer(this.source, {required this.reporter});

  List<Token> tokenize(String sourceCode) {
    final I = _pos;
    _pos = 0;
    _extraSource = sourceCode;
    
    final tokens = lex();
    
    _extraSource = null;
    _pos = I;
    return tokens;
  }
  
  List<Token> lex() {
    final tokens = <Token>[];
    while (!_isAtEnd && !reporter.hasBreakError) {
      Token? token = _nextToken();
      if (token == null) break;
      
      tokens.add(token);
    }

    tokens.add(Token(TokenType.eof, '', _pos));
    return tokens;
  }

  void _skipWhitespace() {
    while (!_isAtEnd && LEXER.whitespaces.contains(_current)) _pos++;
  }

  void _skipLineComment() {
    while (_match(LEXER.LineComment))
      while (!_isAtEnd && !_match('\n')) _pos++;
  }

  void _skipBlockComment() {
    while (_match(LEXER.BlockCommentStart))
      while (!_isAtEnd && !_match(LEXER.BlockCommentEnd)) _pos++;
  }
  
  void _skipComments() {
    while (_is(LEXER.LineComment) || _is(LEXER.BlockCommentStart)) {
      _skipLineComment();
      _skipBlockComment();
      _skipWhitespace();
    }
  }

  Token? _nextToken() {
    _skipWhitespace();
    _skipComments();

    if (_isAtEnd) return null;
    
    for (final op in _operatorMap) {
      final start = _pos;
      if (_match(op.$1))
        return Token(op.$2, op.$1, start);
    }
    
    if (_is(LEXER.Hash))
      return _hex();
      
    final c = _current;
    
    if (_isNumberStart(c))
      return _number();

    if (_isIdentifierStart(c))
      return _identifier();

    _error("Unexpected character: '$c'", _pos);
    _pos++;
    return Token.INVALID;
  }

  Token _hex() {
    final start = _pos;
    _advance(LEXER.Hash);
  
    while (!_isAtEnd && _isHexDigit(_src[_pos])) _pos++;

    final lexeme = _src.substring(start, _pos);
    return Token(TokenType.hexColor, lexeme, start);
  }
  
  Token _identifier() {
    final start = _pos;
    while (!_isAtEnd && _isIdentifierPart(_src[_pos]))
      _pos++;
  
    final name = _src.substring(start, _pos);
    return Token(TokenType.identifier, name, start);
  }

  Token _number() {
    final start = _pos;
    
    // Check for base prefixes
    if (_src[_pos] == '0' && _pos + 1 < _src.length) {
      final nextChar = _src[_pos + 1];
      
      if (nextChar == 'x' || nextChar == 'X') {
        return _hexNumber(start);
      } else if (nextChar == 'b' || nextChar == 'B') {
        return _binaryNumber(start);
      } else if (nextChar == 'o' || nextChar == 'O') {
        return _octalNumber(start);
      }
    }
    
    // Default to decimal (could be integer or float)
    return _decimalNumber(start);
  }
  
  Token _hexNumber(int start) {
    // Skip '0x' or '0X'
    _pos += 2;
    
    if (_isAtEnd || (_isValidNumberBreak(_src[_pos]) && _src[_pos] != LEXER.NumberSeparator)) {
      _error("Incomplete hex number: expected digits after 0x", start, _pos - start);
      return Token.INVALID;
    }
    
    bool separated = false;
    
    while (!_isAtEnd) {
      final c = _src[_pos];
      
      if (c == LEXER.NumberSeparator) {
        if (separated || _pos + 1 >= _src.length) {
          _error("Invalid separator in hex number", _pos);
          return Token.INVALID;
        }

        separated = true;
        _pos++;
        continue;
      }
      
      if (_isHexDigit(c)) {
        separated = false;
        _pos++;
        continue;
      }
      
      if (_isValidNumberBreak(c))
        break;
      else {
         _error("Invalid hex digit: '$c'", _pos);
         return Token.INVALID;
      }
      
    }
    
    final text = _src.substring(start, _pos);
    
    // Must have at least one hex digit after 0x
    if (_pos - start <= 2 ||
      (text.length > 2 && !_isHexDigit(text[text.length - 1]))) {
      _error("Invalid hex number: '$text'", start, _pos - start);
      return Token.INVALID;
    }
    
    return Token(TokenType.hex, text, start);
  }
  
  Token _binaryNumber(int start) {
    // Skip '0b' or '0B'
    _pos += 2;
    
    if (_isAtEnd || (_isValidNumberBreak(_src[_pos]) && _src[_pos] != LEXER.NumberSeparator)) {
      _error("Incomplete binary number: expected digits after 0b", start, _pos - start);
      return Token.INVALID;
    }
    
    bool separated = false;
    
    while (!_isAtEnd) {
      final c = _src[_pos];
      
      if (c == LEXER.NumberSeparator) {
        if (separated || _pos + 1 >= _src.length) {
          _error("Invalid separator in binary number", _pos);
          return Token.INVALID;
        }

        separated = true;
        _pos++;
        continue;
      }
      
      if (_isBinDigit(c)) {
        separated = false;
        _pos++;
        continue;
      }
      
      if (_isValidNumberBreak(c))
        break;
      else {
        _error("Invalid binary digit: '$c'", _pos);
        return Token.INVALID;
      }
      
    }
    
    final text = _src.substring(start, _pos);
    
    // Must have at least one binary digit after 0b
    if (_pos - start <= 2 ||
      (text.length > 2 && !_isBinDigit(text[text.length - 1]))) {
      _error("Invalid binary number: '$text'", start, _pos - start);
      return Token.INVALID;
    }
    
    return Token(TokenType.bin, text, start);
  }
  
  Token _octalNumber(int start) {
    // Skip '0o' or '0O'
    _pos += 2;
    
    if (_isAtEnd || (_isValidNumberBreak(_src[_pos]) && _src[_pos] != LEXER.NumberSeparator)) {
      _error("Incomplete hex number: expected digits after 0o", start, _pos - start);
      return Token.INVALID;
    }
    
    bool separated = false;
    
    while (!_isAtEnd) {
      final c = _src[_pos];
      
      if (c == LEXER.NumberSeparator) {
        if (separated || _pos + 1 >= _src.length) {
          _error("Invalid separator in octal number", start, _pos - start);
          return Token.INVALID;
        }
        
        separated = true;
        _pos++;
        continue;
      }
      
      if (_isOctDigit(c)) {
        separated = false;
        _pos++;
        continue;
      }
      
      if (_isValidNumberBreak(c))
        break;
      else {
        _error("Invalid octal digit: '$c'", _pos);
        return Token.INVALID;
      }
      
    }
    
    final text = _src.substring(start, _pos);
    
    // Must have at least one octal digit after 0o
    if (_pos - start <= 2 ||
      (text.length > 2 && !_isOctDigit(text[text.length - 1]))) {
      _error("Invalid octal number: '$text'", start, _pos - start);
      return Token.INVALID;
    }
    
    return Token(TokenType.oct, text, start);
  }
  
  Token _decimalNumber(int start) {
    bool hasDot = false;
    bool hasExp = false;
    bool separated = false;
    TokenType type = TokenType.int32;
    
    // Check if starts with dot
    if (_src[_pos] == '.') {
      hasDot = true;
      type = TokenType.float32;
      _pos++;
    }
    
    while (!_isAtEnd) {
      final c = _src[_pos];
      
      if (c == LEXER.NumberSeparator) {
        if (separated || _pos + 1 >= _src.length) {
          _error("Invalid separator in decimal number", _pos);
          return Token.INVALID;
        }

        separated = true;
        _pos++;
        continue;
      }
      
      separated = false;
      
      // Handle decimal point
      if (c == '.') {
        if (hasDot || hasExp) {
          _error("Unexpected decimal point", _pos);
          return Token.INVALID;
        }

        hasDot = true;
        type = TokenType.float32;
        _pos++;
        continue;
      }
      
      // Handle exponent
      if (c == 'e' || c == 'E') {
        if (hasExp) {
          _error("Unexpected exponent", _pos);
          return Token.INVALID;
        }
        
        hasExp = true;
        type = TokenType.float32;
        _pos++;
        
        // Optional exponent sign
        if (!_isAtEnd && (_src[_pos] == '+' || _src[_pos] == '-'))
          _pos++;

        continue;
      }
      
      // If it a digit, continue parsing
      if (_isDigit(c)) {
        _pos++;
        continue;
      }
      
      if (_isValidNumberBreak(c))
        break;
      else {
        _error("Invalid decimal digit: '$c'", _pos);
        return Token.INVALID;
      }
      
    }
    
    final text = _src.substring(start, _pos);
    
    // Validate the decimal number
    if (text.isEmpty) {
      _error("Empty number literal", start, _pos - start);
      return Token.INVALID;
    }
    
    if (hasDot && text.endsWith('.')) {
      _error("Incomplete decimal number: '$text'", start, _pos - start);
      return Token.INVALID;
    }
    
    if (hasExp && (text.endsWith('e') || text.endsWith('E') || 
                   text.endsWith('e-') || text.endsWith('E-') ||
                   text.endsWith('e+') || text.endsWith('E+'))) {
      _error("Incomplete exponent in: '$text'", start, _pos - start);
      return Token.INVALID;
    }
    
    return Token(type, text, start);
  }
  
  bool _error(String msg, [int start = -1, int len = 1]) {
    return reporter.push(LexerError(msg, start, len), source: source);
  }
  
  bool _match(String s) {
    if (_src.startsWith(s, _pos)) {
      _pos += s.length;
      return true;
    }
    return false;
  }
  
  bool _is(String c) {
    return _src.startsWith(c, _pos);
  }
  
  bool _advance([String? c]) {
    if (!_isAtEnd) _pos += c?.length ?? 1;
    return !_isAtEnd;
  }
  
  bool _isIdentifierStart(String c) =>
      _isAlpha(c) || c == '_';
      
  bool _isIdentifierPart(String c) =>
      _isAlpha(c) || _isDigit(c) || c == '_';
      
  bool _isNumberStart(String c) =>
      _isDigit(c) || c == '.';

  bool _isValidNumberBreak(String c) =>
    LEXER.whitespaces.contains(c) || LEXER.Operators.contains(c);
      
  bool _isAlpha(String c) =>
      (c.codeUnitAt(0) | 32) >= 97 && (c.codeUnitAt(0) | 32) <= 122;

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  bool _isOctDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 55;
  bool _isBinDigit(String c) => c.codeUnitAt(0) == 48 || c.codeUnitAt(0) == 49;
  bool _isHexDigit(String c) =>
      _isDigit(c) ||
      (c.codeUnitAt(0) | 32) >= 97 && (c.codeUnitAt(0) | 32) <= 102;
}
