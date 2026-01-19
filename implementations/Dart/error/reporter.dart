import 'dart:io';

import '../lexer/source.dart';
import 'errors.dart';

typedef ErrorPrinter = void Function(String);

class ErrorReporter {
  final List<SourceError> _errors = [];
  final List<SourceError> _warnings = [];
  final bool colored;
  final bool breakOnPush;
  final bool printImmediately;
  final ErrorPrinter printer;
  bool enable = true;

  ErrorReporter({
    this.colored = false,
    this.breakOnPush = false,
    this.printImmediately = true,
    ErrorPrinter? printer,
  }) : printer = printer ?? ((s) => stderr.writeln(s));

  // Push an error. Returns true if caller should stop lexing now.
  // If [source] is provided, the error is formatted with context.
  bool push(SourceError e, {Source? source}) {
    if (!enable) return breakOnPush;

    _errors.add(e);
    if (printImmediately) {
      final out = source == null ? e.toString() : e.format(source, colored: colored);
      printer(out);
    }
    return breakOnPush;
  }

  bool pushWarning(SourceError e, {Source? source}) {
    if (!enable) return breakOnPush;

    _warnings.add(e);
    if (printImmediately) {
      final out = source == null ? e.toString() : e.format(source, colored: colored);
      printer(out);
    }
    return breakOnPush;
  }

  bool get hasErrors => _errors.isNotEmpty;
  bool get hasBreakError => breakOnPush && _errors.isNotEmpty;
  List<SourceError> get errors => List.unmodifiable(_errors);
  SourceError? get first => _errors.isEmpty ? null : _errors.first;
  SourceError? get last  => _errors.isEmpty ? null : _errors.last;

  String formattedAll(Source? source) =>
      [..._warnings , ..._errors].map((e) => source == null ? e.toString() : e.format(source, colored: colored)).join('\n\n');

  // If exitNow is true, prints and exits. Otherwise throws an Exception with message.
  void throwIfAny({Source? source, bool exitNow = true}) {
    if (!hasErrors) return;
    final msg = formattedAll(source);

    if (exitNow) {
      printer(msg);
      exit(1);
    } else {
      throw Exception(msg);
    }
  }

  void clear() => _errors.clear();
}