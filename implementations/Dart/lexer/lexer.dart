import '../constants/Lexer.dart' as LEXER;

enum TokenType {
  int32, float32, hex, bin, oct,
  hexColor, identifier, dollar,

  plus, minus, star, slash, percent, intDiv, power,
  bitAnd, bitOr, bitXor, bitNot,
  shiftLeft, shiftRight, rotLeft, rotRight,
  question, colon,

  not, equalEqual, notEqual,
  strictEqual, strictNotEqual, approxEqual, notApproxEqual,
  less, greater, lessEqual, greaterEqual,

  logicalAnd, logicalOr, logicalXor,
  coalesce, guard,

  lParen, rParen, comma,
  eof; 
}

class Token {
  final TokenType type;
  final String lexeme;
  final int start;

  int get len => lexeme.length;
  int get end => start + lexeme.length;

  const Token(this.type, this.lexeme, this.start);
  

  int? asInt() =>
    type == TokenType.int32 ? int.parse(lexeme) : null;
  
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
  final String source;
  int pos = 0;
  
  bool get isAtEnd => pos >= source.length;
  String get current => isAtEnd ? '' : source[pos];

  Lexer(this.source);

  List<Token> lex() {
    final tokens = <Token>[];
    while (!isAtEnd) tokens.add(_nextToken());
    return tokens;
  }

  void _skipWhitespace() {
    while (!isAtEnd && LEXER.whitespaces.contains(current)) pos++;
  }

  void _skipComments() {
    // line comment
    while (_match(LEXER.LineComment))
      while (!isAtEnd && !_match('\n')) pos++;

    // block comment
    while (_match(LEXER.BlockCommentStart))
      while (!isAtEnd && !_match(LEXER.BlockCommentEnd)) pos++;
  }

  Token _nextToken() {
    _skipWhitespace();
    _skipComments();
    _skipWhitespace();

    if (isAtEnd) return Token(TokenType.eof, '', pos);
    
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

    throw FormatException('Unexpected character: $c');
  }

  Token _hex() {
    final start = pos;
    _advance(LEXER.Hash);
  
    while (!isAtEnd && _isHexDigit(source[pos])) pos++;

    final lexeme = source.substring(start, pos);
    return Token(TokenType.hexColor, lexeme, start);
  }
  
  Token _identifier() {
    final start = pos;
    while (!isAtEnd && _isIdentifierPart(source[pos]))
      pos++;
  
    final name = source.substring(start, pos);
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
    
    bool separated = false;
    
    while (!isAtEnd) {
      final c = source[pos];
      
      if (c == LEXER.NumberSeparator) {
        if (separated || pos + 1 >= source.length)
          throw FormatException('Invalid separator in hex number at position $pos');

        separated = true;
        pos++;
        continue;
      }
      
      if (!_isHexDigit(c))
        break;
      
      separated = false;
      pos++;
    }
    
    final text = source.substring(start, pos);
    
    // Must have at least one hex digit after 0x
    if (pos - start <= 2 ||
      (text.length > 2 && !_isHexDigit(text[text.length - 1])))
      throw FormatException('Invalid hex number: $text');
    
    return Token(TokenType.hex, text, start);
  }
  
  Token _binaryNumber(int start) {
    // Skip '0b' or '0B'
    pos += 2;
    
    bool separated = false;
    
    while (!isAtEnd) {
      final c = source[pos];
      
      if (c == LEXER.NumberSeparator) {
        if (separated || pos + 1 >= source.length)
          throw FormatException('Invalid separator in binary number at position $pos');

        separated = true;
        pos++;
        continue;
      }
      
      if (!_isBinDigit(c))
        break;
      
      separated = false;
      pos++;
    }
    
    final text = source.substring(start, pos);
    
    // Must have at least one binary digit after 0b
    if (pos - start <= 2 ||
      (text.length > 2 && !_isBinDigit(text[text.length - 1])))
      throw FormatException('Invalid binary number: $text');
    
    return Token(TokenType.bin, text, start);
  }
  
  Token _octalNumber(int start) {
    // Skip '0o' or '0O'
    pos += 2;
    
    bool separated = false;
    
    while (!isAtEnd) {
      final c = source[pos];
      
      if (c == LEXER.NumberSeparator) {
        if (separated || pos + 1 >= source.length)
          throw FormatException('Invalid separator in octal number at position $pos');
        
        separated = true;
        pos++;
        continue;
      }
      
      if (!_isOctDigit(c))
        break;
      
      separated = false;
      pos++;
    }
    
    final text = source.substring(start, pos);
    
    // Must have at least one octal digit after 0o
    if (pos - start <= 2 ||
      (text.length > 2 && !_isOctDigit(text[text.length - 1])))
      throw FormatException('Invalid octal number: $text');
    
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
        if (separated || pos + 1 >= source.length)
          throw FormatException('Invalid separator in decimal number at position $pos');

        separated = true;
        pos++;
        continue;
      }
      
      separated = false;
      
      // Handle decimal point
      if (c == '.') {
        if (hasDot || hasExp)
          throw FormatException('Unexpected decimal point at position $pos');

        hasDot = true;
        type = TokenType.float32;
        pos++;
        continue;
      }
      
      // Handle exponent
      if (c == 'e' || c == 'E') {
        if (hasExp)
          throw FormatException('Unexpected exponent at position $pos');

        hasExp = true;
        type = TokenType.float32;
        pos++;
        
        // Optional exponent sign
        if (!isAtEnd && (source[pos] == '+' || source[pos] == '-'))
          pos++;

        continue;
      }
      
      // If not a digit, stop parsing
      if (!_isDigit(c))
        break;
      
      pos++;
    }
    
    final text = source.substring(start, pos);
    
    // Validate the decimal number
    if (text.isEmpty)
      throw FormatException('Empty number literal');
    
    if (hasDot && text.endsWith('.'))
      throw FormatException('Incomplete decimal number: $text');
    
    if (hasExp && (text.endsWith('e') || text.endsWith('E') || 
                   text.endsWith('e-') || text.endsWith('E-') ||
                   text.endsWith('e+') || text.endsWith('E+')))
      throw FormatException('Incomplete exponent in: $text');
    
    return Token(type, text, start);
  }
  
  bool _match(String s) {
    if (source.startsWith(s, pos)) {
      pos += s.length;
      return true;
    }
    return false;
  }
  
  bool _is(String c) {
    return source.startsWith(c, pos);
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

  bool _isAlpha(String c) =>
      (c.codeUnitAt(0) | 32) >= 97 && (c.codeUnitAt(0) | 32) <= 122;

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  bool _isOctDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 55;
  bool _isBinDigit(String c) => c.codeUnitAt(0) == 48 || c.codeUnitAt(0) == 49;
  bool _isHexDigit(String c) =>
      _isDigit(c) ||
      (c.codeUnitAt(0) | 32) >= 97 && (c.codeUnitAt(0) | 32) <= 102;
}
