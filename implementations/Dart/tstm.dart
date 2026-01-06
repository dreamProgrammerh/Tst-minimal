import 'dart:io';

import 'error/errors.dart';
import 'error/reporter.dart';
import 'lexer/lexer.dart';
import 'lexer/source.dart';

void main() async {
  const filePath = "examples/theme.tstm";
  
  final out = StringBuffer();
  final reporter = ErrorReporter(
    colord: true,
    breakOnPush: false,
    printImmediately: true,
    printer: (s) => out.writeln(s),
  );

  final source = await Source.from(filePath);
  if (source == null) {
    reporter.push(ResolverError("Source file not found", 0));
    stderr.writeln(out);
    return;
  }

  
  final lexer = Lexer(source, reporter: reporter);
  final tokens = lexer.lex();
  
  if (reporter.hasErrors) {
    stderr.write(out);
    return;
  }
  
  for (var token in tokens) {
    print(token);
  }
}
