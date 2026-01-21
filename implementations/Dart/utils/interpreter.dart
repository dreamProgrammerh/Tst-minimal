import 'dart:io';

import '../error/reporter.dart';
import '../eval/evaluator.dart';
import '../lexer/lexer.dart';
import '../lexer/source.dart';
import '../parser/parser.dart';
import '../runtime/builtins.dart';
import '../runtime/context.dart';
import '../runtime/values.dart';
import 'log.dart' as Log;
import 'run.dart';
import 'string.dart' as StringU;

enum OutputMode {
  none,
  value,
  color,
  code;

  static String? format(RuntimeValue value, OutputMode mode) {
    switch (mode) {
      case OutputMode.none:
        return null;

      case OutputMode.value:
        return Log.stringValue(value);

      case OutputMode.color:
        return Log.stringColor(value);

      case OutputMode.code:
        return Log.stringCode(value);
    }
  }
}

class _SettingArg {
  final String name;
  final List<String>? options;
  final void Function(_SettingArg self,  String input, List<int> selected) action;
  _SettingArg(this.name, this.options, this.action);
}

class TstmInterpreter {
  final ErrorReporter reporter;
  final void Function(RuntimeValue?)? iteration;
  late final MSource source;
  late final EvalContext ctx;
  late final Lexer _lexer;
  late final Parser _parser;
  late final List<_SettingArg> arguments;

  bool _running = false;
  String _prompt = "\x1B[32m\\\x1B[31m>\x1B[0m ";
  List<OutputMode> _outModes = [OutputMode.value];

  TstmInterpreter({
    required this.reporter,
    this.iteration,
    Source? source,
    EvalContext? ctx
  }) {
    initBuiltin();
    _initArgument();

    this.source = MSource(source?.src ?? '', source?.path);
    this._lexer = Lexer(this.source, reporter: reporter);
    this._parser = Parser(this._lexer.lex(), source: this.source, reporter: reporter);
    this.ctx = ctx ?? EvalContext(this._parser.parse());
  }

  // ~~~~~~~~~~~~~~~~~~~~
  //      PUBLIC API
  // ~~~~~~~~~~~~~~~~~~~~

  void start({
    bool clear = true,
    bool title = true}) {
    if (clear)
      _write('\x1B[2J\x1B[H');

    if (title) {
      _write("\x1B[34mTST\x1B[31mm \x1B[32mv\x1B[0m1.0.0\n");
      _write("exit using ctrl+c, or '.exit'\n");
      _write("\x1B[33m'.help' for more information.\x1B[0m\n");
    }

    _running = true;

    RuntimeState.setup(source, reporter);
    while (_running) {
      String? input = _input(_prompt);

      if (input == null) break;

      if (input.trim().isEmpty || _checkArgument(input)) {
        _end();
        continue;
      }

      input = input.trim();
      source.src = input;
      final tokens = _lexer.tokenize(input);

      if (reporter.hasErrors) {
        _end();
        continue;
      }

      final expr = _parser.interpret(tokens);

      if (reporter.hasErrors) {
        _end();
        continue;
      }

      final value = Evaluator.evaluate(expr, ctx);

      if (reporter.hasErrors) {
        _end(value);
        continue;
      }

      _printOutput(value);
      _end(value);
    }
  }

  void stop() {
    _running = false;
  }

  // ~~~~~~~~~~~~~~~~~~~~
  //       Helpers
  // ~~~~~~~~~~~~~~~~~~~~

  void _printOutput(RuntimeValue value) {
    final StringBuffer output = StringBuffer();
    for (int i = 0; i < _outModes.length; i++) {
      final mode = _outModes[i];

      if (mode == OutputMode.none) continue;

      if (i != 0)
        output.write(' '); // separator

      final s = OutputMode.format(value, mode);
      if (s != null)
        output.write(s);
    }

    if (output.isNotEmpty)
      _write('${output.toString()}\n');
  }

  bool _checkArgument(String input) {
    input = input.trimLeft();

    for (final arg in arguments) {
      if (!input.startsWith(arg.name)) continue;
      final inputValue = input.substring(arg.name.length);

      final List<int> selected = [];
      if (arg.options != null && arg.options!.isNotEmpty) {
        if (inputValue.isEmpty) {
          _write('${_getOptionsHelp(arg)}\n');
          return true;
        }

        final selectedOptions = inputValue.trim().split(RegExp(r'\s+'));
        for (int i = 0; i < selectedOptions.length; i++) {
          final opt = selectedOptions[i];
          final index = arg.options!.indexOf(opt);

          if (index == -1) {
            _write("\x1B[31mError:\x1B[0m Unknown option '$opt'\n${_getOptionsHelp(arg)}\n");
            continue;
          }

          selected.add(index);
        }

        if (selectedOptions.isEmpty) {
          _write('${_getOptionsHelp(arg)}\n');
          return true;
        }
      }

      arg.action(arg, inputValue, selected);
      return true;
    }

    return false;
  }

  // ~~~~~~~~~~~~~~~~~~~~
  //        UTILS
  // ~~~~~~~~~~~~~~~~~~~~

  String _getOptionsHelp(_SettingArg arg) {
    return '\x1B[34m>>\x1B[0m ${arg.name} options\n\x1B[33m>\x1B[0m (${arg.options?.join(', ') ?? ''})';
  }

  void _end([RuntimeValue? val]) {
    iteration?.call(val);
    reporter.clear();
  }

  void _write(String str) {
    stdout.write(str);
  }

  String? _input(String? str) {
    if (str != null)
      _write(str);

    return stdin.readLineSync();
  }

  // ~~~~~~~~~~~~~~~~~~~~
  //      ARGUMENTS
  // ~~~~~~~~~~~~~~~~~~~~

  List<int> _runModes = [3];
  List<String> _runModesString = ["none", "tokens", "program", "result"];

  void _initArgument() {
    arguments = [
      _SettingArg('.exit', null, (_, _, _) => stop()),
      _SettingArg('.clear', null, (_, _, _) => _write('\x1B[2J\x1B[H')),
      _SettingArg('.path', null, (_, _, _) => _write('${File('').absolute.path}\n')),
      _SettingArg('.help', null, _argHelp),
      _SettingArg('.prompt', null, _argPrompt),
      _SettingArg('.runmode', _runModesString, _argRunMode),
      _SettingArg('.run', null, (_, input, _) => _argRun(input)),
      _SettingArg('.mode', OutputMode.values.map<String>((e) => e.name).toList(), _argMode),
      _SettingArg('.print', ["colors", "runmode", "mode"], _argPrint),
    ];
  }

  void _argHelp(_SettingArg self, String input, List<int> selected) {
    print(
"""\
type expression to shell to get evaluated,
or start with '.' to use shell arguments:

- .exit: Stop the interpreter.
- .clear: Clear screen.
- .path: Show current path.
- .help: Print this message.
- .prompt: Change interpreter prefix.
- .runmode: Set run print mode.
- .run: Run tstm files.
- .mode: Set interpreter output mode.
- .print: Print different lists and states.\
""");
  }

  void _argPrompt(_SettingArg self, String input, List<int> selected) {
    if (input.isNotEmpty){
      if (input[0] == ' ' && input.length > 1)
        input = input.substring(1);

      _prompt = input;
    }
  }

  void _argRunMode(_SettingArg self, String input, List<int> selected) {
    if (selected.isNotEmpty)
      _runModes = selected;
  }

  Future<void> _argRun(String input) async {
    input = input.trim();
    if (input.isEmpty) return;

    final args = StringU.splitString(input);
    final path = args[0];

    final out = StringBuffer();
    final errorReporter = ErrorReporter(
      colored: true,
      breakOnPush: false,
      printImmediately: true,
      printer: (s) => out.writeln(s),
    );

    TstmRun? runner = TstmRun.syncFrom(path, reporter: errorReporter, buffer: out);
    if (runner == null) {
      _write("\x1B[31mError:\x1B[0m File '$path' not found.\n");
      return;
    }
    
    runner.run(
      printTokens: _runModes.contains(1),
      printProgram: _runModes.contains(2),
      printResult: _runModes.contains(3),
    );
  }

  void _argMode(_SettingArg self, String input, List<int> selected) {
    _outModes = selected.map((i) => OutputMode.values[i]).toList();
  }

  void _argPrint(_SettingArg self, String input, List<int> selected) {
    for (final i in selected) {
      switch (i) {
        case 0:
          Log.printColorLiterals();
          break;

        case 1:
          print(_runModes.map((i) => _runModesString[i]).join(', '));
          break;

        case 2:
          print(_outModes.map((m) => m.name).join(', '));
          break;

        default:
      }
    }
  }
}