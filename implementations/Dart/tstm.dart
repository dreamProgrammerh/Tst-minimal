import 'dart:io';

import 'error/reporter.dart';
import 'shell/completions.dart';
import 'shell/interpreter.dart';
import 'shell/run.dart';
import 'utils/fmath.dart';

void main(List<String> args) async {
  loadFMathLib();
  initCompletions();
  
  final String? filePath = args.isNotEmpty ? args[0] : null;
  final out = StringBuffer();
  final reporter = ErrorReporter(
    colored: true,
    breakOnPush: false,
    printImmediately: true,
    printer: (s) => out.writeln(s),
  );
  

  if (filePath != null) {
    final runner = await TstmRun.from(filePath, reporter: reporter, buffer: out);
    final time = TstmRun.recordTime(() => runner?.run(printResult: false));
  
    print('time: ${time * 0.001}ms');
  } else {
    final interpreter = TstmInterpreter(reporter: reporter, iteration: (_) {
      if (reporter.hasErrors) {
        stderr.write(out);
        out.clear();
      }
    });
    
    interpreter.start();
  }
}