import 'dart:io';

const String whitespaces = ' \t\v\r\f\n';
final String newline = Platform.isWindows ? '\r\n' : '\n';

const LineComment = '//';
const BlockCommentStart = '/*';
const BlockCommentEnd = '*/';

const NumberSeparator = '_';

const RotateLeft = '<<<';
const RotateRight = '>>>';
const ShiftLeft = '<<';
const ShiftRight = '>>';
const IntDiv = '/%';
const Power = '**';
const StrictEqual = '===';
const StrictNotEqual = '!==';
const ApproxEqual = '~=';
const NotApproxEqual = '!~=';
const EqualEqual = '==';
const NotEqual = '!=';
const LessEqual = '<=';
const GreaterEqual = '>=';
const LogicalAnd = '&&';
const LogicalOr = '||';
const LogicalXor = '^^';
const Coalesce = '??';
const Guard = '!!';
const Dollar = '\$';
const BitAnd = '&';
const BitOr = '|';
const BitXor = '^';
const BitNot = '~';
const Plus = '+';
const Minus = '-';
const Star = '*';
const Slash = '/';
const Percent = '%';
const LParen = '(';
const RParen = ')';
const Comma = ',';
const Less = '<';
const Greater = '>';
const Not = '!';
const Question = '?';
const Colon = ':';
const Hash = '#';

const Operators = [
  RotateLeft,
  RotateRight,
  ShiftLeft,
  ShiftRight,
  IntDiv,
  Power,
  StrictEqual,
  StrictNotEqual,
  ApproxEqual,
  NotApproxEqual,
  EqualEqual,
  NotEqual,
  LessEqual,
  GreaterEqual,
  LogicalAnd,
  LogicalOr,
  LogicalXor,
  Coalesce,
  Guard,
  Dollar,
  BitAnd,
  BitOr,
  BitXor,
  BitNot,
  Plus,
  Minus,
  Star,
  Slash,
  Percent,
  LParen,
  RParen,
  Comma,
  Less,
  Greater,
  Not,
  Question,
  Colon,
  Hash,
];
