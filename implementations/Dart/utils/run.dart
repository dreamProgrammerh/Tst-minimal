import 'dart:io';

import '../error/errors.dart';
import '../error/reporter.dart';
import '../eval/evaluator.dart';
import '../lexer/lexer.dart';
import '../lexer/source.dart';
import '../parser/ast.dart';
import '../parser/parser.dart';
import '../primitives/functions/colors.dart';
import '../primitives/functions/math.dart';
import '../runtime/builtins.dart';
import '../runtime/results.dart';
import 'log.dart' as Log;

class RunResult {
  final List<Token>? tokens;
  final Program program;
  final EvalMap result;
  final int lexerTime;
  final int parserTime;
  final int evalTime;
  final int endTime;

  const RunResult({
    required this.tokens,
    required this.program,
    required this.result,
    required this.lexerTime,
    required this.parserTime,
    required this.evalTime,
    required this.endTime
  });
  
  @override
  String toString() {
    return result.toString();
  }
}

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
    return _init(source, buffer, reporter);
  }
  
  static TstmRun? syncFrom(String filePath, {
    required ErrorReporter reporter,
    StringBuffer? buffer
  }) {
    final source = Source.syncFrom(filePath);
    return _init(source, buffer, reporter);
  }
  
  static TstmRun? _init(
    Source? source,
    StringBuffer? buffer,
    ErrorReporter reporter
  ) {  
    if (source == null) {
      reporter.push(ResolverError("Source file not found", -1));
      return null;
    }
    
    return TstmRun(source, reporter: reporter, buffer: buffer);
  }
  
  Future<void> _reload() async {
    if (this._source.path == null) return null;

    final source = await Source.syncFrom(this._source.path!);
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
  
  RunResult? run({
    bool printTokens = false,
    bool printProgram = false,
    bool printResult = false,
    bool useCatch = false,
    bool reload = false,
    int? colorSeed,
    int? mathSeed}) {
    
    if (useCatch && reload)
      throw ArgumentError("You cannot reload while using catched program!");
    
    if (colorSeed != null)
      colorSeedFeed(colorSeed);
    
    if (mathSeed != null)
      mathSeedFeed(mathSeed);
    
    int lexerTime, parserTime, evalTime, endTime;
    
    if (reload)
      _reload();
          
    List<Token>? tokens;
    Program? program;
    parserTime = lexerTime = _now();
    
    if (useCatch && _programCatch != null) {
      program = _programCatch!;
      
    } else {
      lexerTime = _now();
      tokens = Lexer(_source, reporter: reporter).lex();
    
      if (reporter.hasErrors) {
        stderr.write(buffer);
        return null;
      }
    
      if (printTokens)
        for (final token in tokens) print(token);
    
      parserTime = _now();
      program = Parser(tokens, source: _source, reporter: reporter).parse();
    
      if (reporter.hasErrors) {
        stderr.write(buffer);
        return null;
      }
      
      _programCatch = program;
      
      if (printProgram)
        print(program);
    }
    
    evalTime = _now();
    final evalMap = Evaluator(program, source: _source, reporter: reporter).eval();
  
    if (reporter.hasErrors) {
      stderr.write(buffer);
      return null;
    }
    
    if (printResult)
      Log.printEval(evalMap);
    
    endTime = _now();
    
    return RunResult(
      tokens: tokens,
      program: program,
      result: evalMap,
      lexerTime: lexerTime,
      parserTime: parserTime,
      evalTime: evalTime,
      endTime: endTime
    );
  }
}