import 'dart:io';

import '../constants/const-signature.dart';
import '../primitives/functions/colors.dart';
import '../primitives/functions/math.dart';
import '../primitives/functions/print.dart';
import '../primitives/functions/solid.dart';
import '../primitives/literals/colors.dart';
import '../runtime/context.dart';
import '../runtime/results.dart';
import '../runtime/values.dart';
import 'color.dart' as Colors;
import 'help.dart';

class _TableRow {
  int color;
  String name;
  String value;
  String code;
  
  _TableRow({
    this.color  = 0,
    this.name   = '',
    this.value  = '',
    this.code    = '',
  });
  
  @override
  String toString() =>
    '(${colorBlock(color)}, $name, $value, $code)';
}

@pragma('vm:perfer-inline')
int _max(int a, int b) => a > b ? a : b;

@pragma('vm:perfer-inline')
int _getColor(RuntimeValue val) => val is IntValue ? val.value : 0;

@pragma('vm:perfer-inline')
String _ansiBGColor(int argb) =>
  '\x1B[48;2;${
  (argb >> 16) & 0xFF};${
  (argb >> 8) & 0xFF};${
  argb & 0xFF}m';

  @pragma('vm:perfer-inline')

@pragma('vm:perfer-inline')
// ignore: unused_element
String _ansiColor(int argb) =>
  '\x1B[38;2;${
  (argb >> 16) & 0xFF};${
  (argb >> 8) & 0xFF};${
  argb & 0xFF}m';

const _colorBlockLength = 2;

@pragma('vm:perfer-inline')
String colorBlock(int argb) {
  // ignore: unused_local_variable
  const invalidColor = "\x1b[40m \x1b[45m \x1b[0m";
  
  return argb == 0
    ? '\x1B[0m  '
    : '${_ansiBGColor(argb)}  \x1B[0m';
}

@pragma('vm:perfer-inline')
String gradientBlock(List<int> argbs) {
  if (argbs.isEmpty)
    return '\x1B[0m  ';

  final sb = StringBuffer();
  
  for (final argb in argbs) {
    sb.write('${_ansiBGColor(argb)} ');
  }
  
  sb.write('\x1b[0m');
  return sb.toString();
}

List<int> gradientSmooth(List<int> argbs, [int length = 3]) {
  if (argbs.isEmpty)
    return [];
    
  if (length <= 0)
    return List.from(argbs);

  final g = <int>[];
  
  int? lastColor;
  for (final argb in argbs) {
    if (lastColor != null) {
      final p = 1.0 / length;
      for (int i = 1; i < length; i++) {
        g.add(Colors.mix(lastColor, argb, p * i));
      }
    }
    
    g.add(argb);
    lastColor = argb;
  }
  
  return g;
}

@pragma('vm:perfer-inline')
String stringValue(RuntimeValue val) => val.stringify();

@pragma('vm:perfer-inline')
String stringColor(RuntimeValue val) => colorBlock(_getColor(val));

@pragma('vm:perfer-inline')
String stringCode(RuntimeValue val) {
  if (val is IntValue)
    return '#${val.value
      .toUnsigned(32)
      .toRadixString(16)
      .padLeft(8, '0')
      .toUpperCase()
    }';
    
  else if (val is FloatValue)
    return '${val.value.toStringAsExponential(4)}';
    
  else
    return val.stringify();
} 

@pragma('vm:perfer-inline')
String stringColoredCode(RuntimeValue val) {
  final code = stringCode(val);
  
  if (val is IntValue) {
    return '\x1B[33m#\x1B[37m${
      code.substring(1, 3)}\x1B[31m${
      code.substring(3, 5)}\x1B[32m${
      code.substring(5, 7)}\x1B[34m${
      code.substring(7, 9)}\x1B[0m';
  
  } else if (val is FloatValue) {
    final eIndex = code.lastIndexOf('e');
    return '\x1B[33m${
      code.substring(0, eIndex)}\x1B[34m${
      code.substring(eIndex)}\x1B[0m';
  
  } else
    return '\x1B[33m$code\x1B[0m';
}

@pragma('vm:perfer-inline')
String stringInfo(RuntimeValue val) {
  const keyColor = "\x1B[34m";
  const valColor = "\x1B[33m";
  
  if (val is IntValue) {
    return (
      "${stringColor(val)}"
      "${stringColoredCode(val)} \x1B[39m| "
      "${keyColor}isDark: $valColor${Colors.isDark(val.value)}\x1B[39m, "
      "${keyColor}temperature: $valColor${Colors.getTemperature(val.value).toStringAsFixed(2)}"
      "\x1B[0m"
    );
    
  } else {
    return stringColoredCode(val);
  }
}

void printEval<T extends EvalResult>(T result) {
  StringBuffer sb = StringBuffer();
  
  // variables
  const int
    spaceAround = 2;
  
  const String
    reset = "\x1B[0m",
    tableColor = "\x1B[32m",
    nameColor = "\x1B[34m",
    valueColor = "\x1B[33m",
    codeColor = "\x1B[36m",
    
    emptyTable = "No Data",
    colorTitle = "Color",
    nameTitle = "Name",
    valueTitle = "Value",
    codeTitle = "Code";
    
  final sideSpace = ' ' * (spaceAround ~/ 2);

  // columns length
  int
    maxColorLength = _max(_colorBlockLength, colorTitle.length),
    maxNameLength = _max(10, nameTitle.length),
    maxValueLength = _max(12, valueTitle.length),
    maxCodeLength = _max(10, codeTitle.length);

  
  // case for empty result
  if (result.length == 0) {
    final width = maxColorLength + maxNameLength + maxValueLength + maxCodeLength
      + (spaceAround * 4) // spaces around
      + 5; // pipes  |
    
    final remaining = width - emptyTable.length - 2;
    final lSpace = remaining ~/ 2;
    final rSpace = remaining - lSpace;
    
    sb.write(
      '$tableColor|${'-' * (width - 2)}|\n'
      '|${' ' * lSpace}$emptyTable${' ' * rSpace}|\n'
      '|${'-' * (width - 2)}|$reset\n'
    );
    
    stdout.write(sb.toString());
    return;
  }
  
  // organize the table
  final table = List<_TableRow>.generate(result.length,
    (_) => new _TableRow(
      color: 0,
      name: '',
      value: '',
      code: ''
    ), growable: false);
  
  // fill table with data
  int i = 0;
  result.reset();
  while (result.next()) {
    final entry = result.current;
    if (entry == null) break;
    
    _TableRow row = table[i++];
    
    // Name column
    row.name = entry.key;
    maxNameLength = _max(maxNameLength, row.name.length);
    
    // Value column
    row.value = stringValue(entry.value);
    maxValueLength = _max(maxValueLength, row.value.length);
        
    // Color column
    row.color = _getColor(entry.value);
    // maxColorLength = _max(maxColorLength, ...); // no need its always 2
    
    // Code column
    row.code = stringCode(entry.value);
    maxCodeLength = _max(maxCodeLength, row.code.length);
  }
  i = 0;
  result.reset();
  
  // build table header
  sb.write(
    "$tableColor"
    "|$sideSpace${colorTitle.padRight(maxColorLength)}$sideSpace"
    "|$sideSpace${nameTitle.padRight(maxNameLength)}$sideSpace"
    "|$sideSpace${valueTitle.padRight(maxValueLength)}$sideSpace"
    "|$sideSpace${codeTitle.padRight(maxCodeLength)}$sideSpace"
    "|$reset\n"
  );
  
  sb.write(
    "$tableColor"
    "|${'-' * (maxColorLength + spaceAround)}"
    "|${'-' * (maxNameLength + spaceAround)}"
    "|${'-' * (maxValueLength + spaceAround)}"
    "|${'-' * (maxCodeLength + spaceAround)}"
    "|$reset\n"
  );

  // build table body
  for (final row in table) {
    final color = colorBlock(row.color);
    final colorPad = maxColorLength + (color.length - _colorBlockLength);
    
    sb.write(
      "$tableColor|$sideSpace"
      "${color.padRight(colorPad)}$sideSpace"
      "$tableColor|$sideSpace"
      "$nameColor${row.name.padRight(maxNameLength)}$sideSpace"
      "$tableColor|$sideSpace"
      "$valueColor${row.value.padRight(maxValueLength)}$sideSpace"
      "$tableColor|$sideSpace"
      "$codeColor${row.code.padRight(maxCodeLength)}$sideSpace"
      "$tableColor|$reset\n"
    );
  }

  // print table
  stdout.write(sb.toString());
}

void printColorLiterals() {
  final EvalList list = EvalList(
    List.generate(colorLiterals.length,
      (i) {
        final lit = colorLiterals[i];
        return EvalEntry(key: lit.$1, value: IntValue(lit.$2));
      },
      growable:  false
  ));
  
  printEval(list);
}

void printBuiltinFunctions() {
  const pre = '$sigTitleColor  * ';
  final sb = StringBuffer();
  
  sb.write("${sigTitleColor}Solid:$sigReset\n");
  for (final func in solidFuncs)
    sb.write('$pre${functionString(func.$1, func.$2, func.$3)}\n'); 
  
  sb.write("\n${sigTitleColor}Print:$sigReset\n");
  for (final func in printFuncs)
    sb.write('$pre${functionString(func.$1, func.$2, func.$3)}\n'); 
    
  sb.write("\n${sigTitleColor}Math:$sigReset\n");
  for (final func in mathFuncs)
    sb.write('$pre${functionString(func.$1, func.$2, func.$3)}\n'); 
  
  sb.write("\n${sigTitleColor}Colors:$sigReset\n");
  for (final func in colorFuncs)
    sb.write('$pre${functionString(func.$1, func.$2, func.$3)}\n'); 

  
  sb.write('$sigReset');
  stdout.write(sb.toString());
}

String functionString(String fnName, [Signature? s, List<String>? names]) {
  if (s == null) return "$sigNameColor$fnName$sigPunchColor($sigArgNameColor${names?[0] ?? ''}...$sigPunchColor)$sigReset";
  
  final sb = StringBuffer('$sigNameColor$fnName$sigPunchColor(');
  
  int I = 0;
  for (final types in s) {
    if (I != 0) sb.write('$sigPunchColor, ');
    
    final extendArg = types & AT_extend != 0;
    final optionalArg = types & AT_optional != 0;
    
    final name = names?[I];
    if (name != null)
      sb.write(
        '$sigArgNameColor'
        '${extendArg? '...' : ''}$name${optionalArg ? '?' : ''}: '
      );
      
    else if (extendArg || optionalArg)
      sb.write(
        '$sigArgNameColor'
        '${extendArg ? '...' : ''}${optionalArg ? '?' : ''} '
      );
    
    int J = 0;
    for (int i = AL_Idx; i < AL_Types.length; i++) {
      final type = AL_Types[i];
      if (types & type != 0) {
        if (J != 0) sb.write('$sigSepColor | ');
        sb.write('$sigArgTypeColor${AL_Names[i]}');
        J++;
      }
    }
    I++;
  }
  
  sb.write('$sigPunchColor)$sigReset');
  return sb.toString();
}

void printAvailableHelps() {
  const helpColor = "\x1B[35m";
  const preColor = "\x1B[34m";
  const pre = '$sigTitleColor  * ';
  
  final helps = getAvailableHelps();
  final sb = StringBuffer("${preColor}All Helps:\n");
  
  for (final h in helps)
    sb.write('$preColor$pre$helpColor$h\n');
  
  sb.write('\x1B[0m');
  stdout.write(sb.toString());
}