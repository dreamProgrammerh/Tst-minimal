import 'dart:io';

import 'error/errors.dart';
import 'error/reporter.dart';
import 'eval/evaluator.dart';
import 'lexer/lexer.dart';
import 'lexer/source.dart';
import 'parser/parser.dart';
import 'runtime/builtins.dart';

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

  // for (var token in tokens) {
  //   print(token);
  // }

  final parser = Parser(tokens, source: source, reporter: reporter);
  final program = parser.parse();

  if (reporter.hasErrors) {
    stderr.write(out);
    return;
  }

  // print(program);
  
  initBuiltin();
  final evaluator = Evaluator(program, source: source, reporter: reporter);
  final evalMap = evaluator.eval();

  if (reporter.hasErrors) {
    stderr.write(out);
    return;
  }
  
  for (final en in evalMap.entries) {
    print('${en.key}: ${en.value}');
  }
}
