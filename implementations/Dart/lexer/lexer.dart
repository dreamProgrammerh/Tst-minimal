enum TokenType {
  int32, float32,
  identifier, dollar,

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

  Token(this.type, this.lexeme, this.start);
  

  int? asInt() =>
    type == TokenType.int32 ? int.parse(lexeme) : null;
  
  double? asFloat() =>
    type == TokenType.float32 ? double.parse(lexeme) : null;
  
  @override
  String toString() => '$type($lexeme)';
}
