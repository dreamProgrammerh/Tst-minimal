import 'dart:io';

import '../lexer/source.dart';

// Base class for all source‑related errors.
abstract class SourceError {
  void Throw(Source src, [bool caught = false]) {
    stderr.writeln(format(src));
    if (!caught) exit(1);
  }

  final String message;
  final int offset;
  final int length;

  SourceError(this.message, this.offset, [this.length = 1]);

  // Compute line/column and pretty‑print the error with context.
  String format(Source source) {
    int line = 1, col = 1;
    int lineStart = 0;
    for (int i = 0; i < offset && i < source.length; i++) {
      if (source.src.codeUnitAt(i) == 0x0A) {
        line++;
        col = 1;
        lineStart = i + 1;
      } else {
        col++;
      }
    }

    int lineEnd = source.src.indexOf('\n', lineStart);
    if (lineEnd == -1) lineEnd = source.length;
    final lineText = source.chunk(lineStart, lineEnd);

    // If column is after lineText, we still render the line and place a single caret at that column.
    final maxAvailable = (lineText.length - (col - 1));
    final caretCount = (maxAvailable > 0) ? (length.clamp(1, maxAvailable)) : 1;

    final underline = ' ' * (col - 1) + '^' * caretCount;

    return '$runtimeType($message) at @$line:$col\n'
           '$lineText\n'
           '$underline';
  }

  @override
  String toString() => '$runtimeType($message) at offset $offset';
}

// Specific error types
class LexerError extends SourceError {
  LexerError(super.message, super.offset, [super.length]);
}

class ParserError extends SourceError {
  ParserError(super.message, super.offset, [super.length]);
}