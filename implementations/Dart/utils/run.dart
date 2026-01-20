import 'dart:io';

import '../constants/const-functions.dart';
import '../error/errors.dart';
import '../error/reporter.dart';
import '../eval/evaluator.dart';
import '../lexer/lexer.dart';
import '../lexer/source.dart';
import '../parser/ast.dart';
import '../parser/parser.dart';
import '../runtime/builtins.dart';
import '../runtime/results.dart';
import 'log.dart' as Log;

int _now() => DateTime.now().microsecondsSinceEpoch;

class TstmRun {
  final ErrorReporter reporter;
  final StringBuffer buffer;
  Source _source;
  Program? _programCatch;
  
  TstmRun(this._source, {
    required this.reporter,
    StringBuffer? buffer
  }): buffer = buffer ?? StringBuffer() {
    initBuiltin();
  }
  
  static Future<TstmRun?> from(String filePath, {
    required ErrorReporter reporter,
    StringBuffer? buffer
  }) async {
    final source = await Source.from(filePath);
    if (source == null) {
      reporter.push(ResolverError("Source file not found", -1));
      return null;
    }
    
    return TstmRun(source, reporter: reporter, buffer: buffer);
  }
  
  Future<void> _reload() async {
    if (this._source.path == null) return null;

    final source = await Source.from(this._source.path!);
    if (source == null) {
      reporter.push(ResolverError("Source file not found", -1));
      return null;
    }
    
    this._source = source;
  }
  
  static int recordTime(void Function() fn) {
    final start = _now();
    fn();
    final end = _now();
    
    return end - start;
  }
  
  EvalMap? run({
    bool printTokens = false,
    bool printProgram = false,
    bool printResult = false,
    bool useCatch = false,
    bool reload = false,
    int? seed}) {
    
    if (useCatch && reload)
      throw ArgumentError("You cannot reload while using catched program!");
    
    if (seed != null) 
      randomSeed(seed);
    
    bool wait = false;
    
    if (reload) {
      wait = true;
      _reload().whenComplete(() => wait = false);
    }
      
    while(wait);
    
    Program? program;
    if (useCatch && _programCatch != null) {
      program = _programCatch!;
      
    } else {
      final tokens = Lexer(_source, reporter: reporter).lex();
    
      if (reporter.hasErrors) {
        stderr.write(buffer);
        return null;
      }
    
      if (printTokens)
        for (final token in tokens) print(token);
    
      program = Parser(tokens, source: _source, reporter: reporter).parse();
    
      if (reporter.hasErrors) {
        stderr.write(buffer);
        return null;
      }
      
      _programCatch = program;
      
      if (printProgram)
        print(program);
    }
    
    final evalMap = Evaluator(program, source: _source, reporter: reporter).eval();
  
    if (reporter.hasErrors) {
      stderr.write(buffer);
      return null;
    }
    
    if (printResult)
      Log.printEval(evalMap);
    
    return evalMap;
  }
}