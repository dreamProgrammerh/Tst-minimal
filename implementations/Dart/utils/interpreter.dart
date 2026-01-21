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

enum OutputMode {
  none,
  value,
  color,
  code,
  valueAndCode,
  colorAndCode,
  valueAndColorAndCode,
}

class InterpreterArg {
  final String name;
  final List<String>? options;
  final void Function(InterpreterArg self, int index) action;
  InterpreterArg(this.name, this.options, this.action);
}

class TstmInterpreter {
  final ErrorReporter reporter;
  final void Function(RuntimeValue?)? iteration;
  late final MSource source;
  late final EvalContext ctx;
  late final Lexer _lexer;
  late final Parser _parser;
  bool _running = false;
  OutputMode _mode = OutputMode.value;
  
  late final List<InterpreterArg> arguments;
  
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
        
      case OutputMode.valueAndCode:
        return '${Log.stringValue(value)} ${Log.stringCode(value)}';
       
      case OutputMode.colorAndCode:
        return '${Log.stringColor(value)} ${Log.stringCode(value)}';
      
      case OutputMode.valueAndColorAndCode:
        return '${Log.stringValue(value)} ${Log.stringColor(value)} ${Log.stringCode(value)}';
    }
  }
  
  void _initArgument() {
    arguments = [
      InterpreterArg('.exit', null, (_, _) => stop()),
      InterpreterArg('.clear', null, (_, _) => _write('\x1B[2J\x1B[H')),
      InterpreterArg('.mode',
        OutputMode.values.map<String>((e) => e.name).toList(),
        (_, i) => _mode = OutputMode.values[i]
      ),
      InterpreterArg('.print', ["colors"], (_, i) {
          switch (i) {
            case 0:
              Log.printColorLiterals();
              break;
            
            default:
          }
        }
      ),
    ];
  }
  
  void _write(String str) {
    stdout.write(str);
  }
  
  String? _input(String? str) {
    if (str != null)
      _write(str);
      
    return stdin.readLineSync();
  }
  
  void _end([RuntimeValue? val]) {
    iteration?.call(val);
    reporter.clear();
  }
  
  void stop() {
    _running = false;
  }
  
  void start({
    bool clear = true,
    bool title = true}) {
    if (clear)
      _write('\x1B[2J\x1B[H');
    
    if (title)
      _write("\x1B[34mTST\x1B[31mm \x1B[32mv\x1B[0m1.0.0\n");
    
    _running = true;
    
    RuntimeState.setup(source, reporter);
    while (_running) {
      String? input = _input('\x1B[32m\\\x1B[31m>\x1B[0m ');
      
      if (input == null) break;
      input = input.trim();
      
      if (input.isEmpty || _checkArgument(input)) {
        _end();
        continue;
      }
      
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
      
      final output = format(value, _mode);
      if (output != null)
        _write('${output}\n');
      
      _end(value);
    }
  }
  
  bool _checkArgument(String input) {
    for (final arg in arguments) {
      if (!input.startsWith(arg.name)) continue;
      
      int index = -1;
      if (arg.options != null && arg.options!.isNotEmpty) {
        final option = input.substring(arg.name.length).trim();
        index = arg.options!.indexWhere((opt) => opt == option);
        
        if (index == -1) {
          _write('\x1B[31mError:\x1B[0m ${arg.name} options\n(${arg.options!.join(', ')})\n');
          return true;
        }
      }
      
      arg.action(arg, index);
      return true;
    }
    
    return false;
  }
}