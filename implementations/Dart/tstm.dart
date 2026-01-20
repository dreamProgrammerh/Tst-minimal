import 'error/reporter.dart';
import 'utils/run.dart';

void main() async {
  const filePath = "examples/theme.tstm";
  
  final out = StringBuffer();
  final reporter = ErrorReporter(
    colored: true,
    breakOnPush: false,
    printImmediately: true,
    printer: (s) => out.writeln(s),
  );

  final runner = await TstmRun.from(filePath, reporter: reporter, buffer: out);

  final time1 = TstmRun.recordTime(() => runner?.run(printResult: true));

  final time2 = TstmRun.recordTime(() => runner?.run(useCatch: true));
  
  print('without catch: ${time1 / 1000}ms');
  print('with catch:    ${time2 / 1000}ms');
}