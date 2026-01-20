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
  int pos = 0;
  
  bool get isAtEnd => pos >= source.length;
  String get current => isAtEnd ? '' : source[pos];

  Lexer(this.source, {required this.reporter});

  List<Token> lex() {
    final tokens = <Token>[];
    while (!isAtEnd && !reporter.hasBreakError) {
      Token? token = _nextToken();
      if (token == null) break;
      
      tokens.add(token);
    }

    tokens.add(Token(TokenType.eof, '', pos));
    return tokens;
  }

  void _skipWhitespace() {
    while (!isAtEnd && LEXER.whitespaces.contains(current)) pos++;
  }

  void _skipLineComment() {
    while (_match(LEXER.LineComment))
      while (!isAtEnd && !_match('\n')) pos++;
  }

  void _skipBlockComment() {
    while (_match(LEXER.BlockCommentStart))
      while (!isAtEnd && !_match(LEXER.BlockCommentEnd)) pos++;
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

    if (isAtEnd) return null;
    
    for (final op in _operatorMap) {
      final start = pos;
      if (_match(op.$1))
        return Token(op.$2, op.$1, start);
    }
    
    if (_is(LEXER.Hash))
      return _hex();
      
    final c = current;
    
    if (_isNumberStart(c))
      return _number();

    if (_isIdentifierStart(c))
      return _identifier();

    _error("Unexpected character: '$c'", pos);
    return Token.INVALID;
  }

  Token _hex() {
    final start = pos;
    _advance(LEXER.Hash);
  
    while (!isAtEnd && _isHexDigit(source[pos])) pos++;

    final lexeme = source.chunk(start, pos);
    return Token(TokenType.hexColor, lexeme, start);
  }
  
  Token _identifier() {
    final start = pos;
    while (!isAtEnd && _isIdentifierPart(source[pos]))
      pos++;
  
    final name = source.chunk(start, pos);
    return Token(TokenType.identifier, name, start);
  }

  Token _number() {
    final start = pos;
    
    // Check for base prefixes
    if (source[pos] == '0' && pos + 1 < source.length) {
      final nextChar = source[pos + 1];
      
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
    pos += 2;
    
    if (isAtEnd || (_isValidNumberBreak(source[pos]) && source[pos] != LEXER.NumberSeparator)) {
      _error("Incomplete hex number: expected digits after 0x", start, pos - start);
      return Token.INVALID;
    }
    
    bool separated = false;
    
    while (!isAtEnd) {
      final c = source[pos];
      
      if (c == LEXER.NumberSeparator) {
        if (separated || pos + 1 >= source.length) {
          _error("Invalid separator in hex number", pos);
          return Token.INVALID;
        }

        separated = true;
        pos++;
        continue;
      }
      
      if (_isHexDigit(c)) {
        separated = false;
        pos++;
        continue;
      }
      
      if (_isValidNumberBreak(c))
        break;
      else {
         _error("Invalid hex digit: '$c'", pos);
         return Token.INVALID;
      }
      
    }
    
    final text = source.chunk(start, pos);
    
    // Must have at least one hex digit after 0x
    if (pos - start <= 2 ||
      (text.length > 2 && !_isHexDigit(text[text.length - 1]))) {
      _error("Invalid hex number: '$text'", start, pos - start);
      return Token.INVALID;
    }
    
    return Token(TokenType.hex, text, start);
  }
  
  Token _binaryNumber(int start) {
    // Skip '0b' or '0B'
    pos += 2;
    
    if (isAtEnd || (_isValidNumberBreak(source[pos]) && source[pos] != LEXER.NumberSeparator)) {
      _error("Incomplete binary number: expected digits after 0b", start, pos - start);
      return Token.INVALID;
    }
    
    bool separated = false;
    
    while (!isAtEnd) {
      final c = source[pos];
      
      if (c == LEXER.NumberSeparator) {
        if (separated || pos + 1 >= source.length) {
          _error("Invalid separator in binary number", pos);
          return Token.INVALID;
        }

        separated = true;
        pos++;
        continue;
      }
      
      if (_isBinDigit(c)) {
        separated = false;
        pos++;
        continue;
      }
      
      if (_isValidNumberBreak(c))
        break;
      else {
        _error("Invalid binary digit: '$c'", pos);
        return Token.INVALID;
      }
      
    }
    
    final text = source.chunk(start, pos);
    
    // Must have at least one binary digit after 0b
    if (pos - start <= 2 ||
      (text.length > 2 && !_isBinDigit(text[text.length - 1]))) {
      _error("Invalid binary number: '$text'", start, pos - start);
      return Token.INVALID;
    }
    
    return Token(TokenType.bin, text, start);
  }
  
  Token _octalNumber(int start) {
    // Skip '0o' or '0O'
    pos += 2;
    
    if (isAtEnd || (_isValidNumberBreak(source[pos]) && source[pos] != LEXER.NumberSeparator)) {
      _error("Incomplete hex number: expected digits after 0o", start, pos - start);
      return Token.INVALID;
    }
    
    bool separated = false;
    
    while (!isAtEnd) {
      final c = source[pos];
      
      if (c == LEXER.NumberSeparator) {
        if (separated || pos + 1 >= source.length) {
          _error("Invalid separator in octal number", start, pos - start);
          return Token.INVALID;
        }
        
        separated = true;
        pos++;
        continue;
      }
      
      if (_isOctDigit(c)) {
        separated = false;
        pos++;
        continue;
      }
      
      if (_isValidNumberBreak(c))
        break;
      else {
        _error("Invalid octal digit: '$c'", pos);
        return Token.INVALID;
      }
      
    }
    
    final text = source.chunk(start, pos);
    
    // Must have at least one octal digit after 0o
    if (pos - start <= 2 ||
      (text.length > 2 && !_isOctDigit(text[text.length - 1]))) {
      _error("Invalid octal number: '$text'", start, pos - start);
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
    if (source[pos] == '.') {
      hasDot = true;
      type = TokenType.float32;
      pos++;
    }
    
    while (!isAtEnd) {
      final c = source[pos];
      
      if (c == LEXER.NumberSeparator) {
        if (separated || pos + 1 >= source.length) {
          _error("Invalid separator in decimal number", pos);
          return Token.INVALID;
        }

        separated = true;
        pos++;
        continue;
      }
      
      separated = false;
      
      // Handle decimal point
      if (c == '.') {
        if (hasDot || hasExp) {
          _error("Unexpected decimal point", pos);
          return Token.INVALID;
        }

        hasDot = true;
        type = TokenType.float32;
        pos++;
        continue;
      }
      
      // Handle exponent
      if (c == 'e' || c == 'E') {
        if (hasExp) {
          _error("Unexpected exponent", pos);
          return Token.INVALID;
        }
        
        hasExp = true;
        type = TokenType.float32;
        pos++;
        
        // Optional exponent sign
        if (!isAtEnd && (source[pos] == '+' || source[pos] == '-'))
          pos++;

        continue;
      }
      
      // If it a digit, continue parsing
      if (_isDigit(c)) {
        pos++;
        continue;
      }
      
      if (_isValidNumberBreak(c))
        break;
      else {
        _error("Invalid decimal digit: '$c'", pos);
        return Token.INVALID;
      }
      
    }
    
    final text = source.chunk(start, pos);
    
    // Validate the decimal number
    if (text.isEmpty) {
      _error("Empty number literal", start, pos - start);
      return Token.INVALID;
    }
    
    if (hasDot && text.endsWith('.')) {
      _error("Incomplete decimal number: '$text'", start, pos - start);
      return Token.INVALID;
    }
    
    if (hasExp && (text.endsWith('e') || text.endsWith('E') || 
                   text.endsWith('e-') || text.endsWith('E-') ||
                   text.endsWith('e+') || text.endsWith('E+'))) {
      _error("Incomplete exponent in: '$text'", start, pos - start);
      return Token.INVALID;
    }
    
    return Token(type, text, start);
  }
  
  bool _error(String msg, [int start = -1, int len = 1]) {
    return reporter.push(LexerError(msg, start, len), source: source);
  }
  
  bool _match(String s) {
    if (source.src.startsWith(s, pos)) {
      pos += s.length;
      return true;
    }
    return false;
  }
  
  bool _is(String c) {
    return source.src.startsWith(c, pos);
  }
  
  bool _advance([String? c]) {
    if (!isAtEnd) pos += c?.length ?? 1;
    return !isAtEnd;
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
