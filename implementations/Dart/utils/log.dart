import '../constants/const-literals.dart' as LITERALS;
import '../runtime/context.dart';
import '../runtime/values.dart';
import 'colors.dart';

class _TableRow {
  String color;
  String name;
  String value;
  String code;
  
  _TableRow({
    this.color  = '',
    this.name   = '',
    this.value  = '',
    this.code    = '',
  });
  
  @override
  String toString() {
    return '($color, $name, $value, $code)';
  }
}

int _max(int a, int b) {
  return a > b ? a : b;
}

double _round(double a, int b) {
  return double.parse(a.toStringAsFixed(b));
}

void printEval<T extends Iterable>(T map) {
  StringBuffer sb = StringBuffer();
  
  // varibles
  final int
    colorBlock = 2,
    spaceAround = 2;
  
  final String
    reset = "\x1B[0m",
    tableColor = "\x1B[32m",
    nameColor = "\x1B[34m",
    valueColor = "\x1B[33m",
    codeColor = "\x1B[36m",
    
    sideSpace = ' ' * (spaceAround ~/ 2), 
    invalidValue = "Invalid",
    colorTitle = "Color",
    nameTitle = "Name",
    valueTitle = "Value",
    codeTitle = "Code";

  // columns length
  int
    maxColorLength = _max(colorBlock, colorTitle.length),
    maxNameLength = _max(10, nameTitle.length),
    maxValueLength = _max(12, valueTitle.length),
    maxCodeLength = _max(10, codeTitle.length);

  
  // organize the table
  List<_TableRow> table = List.generate(map.length,
    (_) => new _TableRow(
      color: '',
      name: '',
      value: '',
      code: ''
    ), growable: false);
  
  // fill table with data
  int i = 0;
  for (final entry in map) {
    _TableRow row = table[i++];
    // name column
    row.name = entry.key;
    maxNameLength = _max(maxNameLength, row.name.length);
    
    // value column
    row.value = entry.value is IntValue
      ? (entry.value as IntValue).value.toString()
      : entry.value is FloatValue
        ? _round((entry.value as FloatValue).value, 6).toString()
        : "invalid";
    
    maxValueLength = _max(maxValueLength, row.value.length);
        
    
    // color column
    if (entry.value is IntValue) {
      final v = entry.value as IntValue;
      row.color = '\x1B[7m${ansiColoredText(' ' * colorBlock, v.value)}';
    } else {
      row.color = ' ' * colorBlock;
    }
    
    // color column
    row.code = entry.value is IntValue
      ? '#${(entry.value as IntValue).value.toUnsigned(32).toRadixString(16).padRight(8, '0').toUpperCase()}'
      : entry.value is FloatValue
        ? '${(entry.value as FloatValue).value.toStringAsExponential(4)}'
        : invalidValue.padLeft( // padCenter
          (maxCodeLength - invalidValue.length) ~/ 2 + invalidValue.length);
    
    maxCodeLength = _max(maxCodeLength, row.code.length);
  }
  i = 0;

  
  // build table header
  sb.write("$tableColor|$sideSpace${
    colorTitle.padRight(maxColorLength)
  }$sideSpace|$sideSpace${
    nameTitle.padRight(maxNameLength)
  }$sideSpace|$sideSpace${
    valueTitle.padRight(maxValueLength)
  }$sideSpace|$sideSpace${
    codeTitle.padRight(maxCodeLength)
  }$sideSpace|$reset\n");
  
  sb.write("$tableColor|${
    '-' * (maxColorLength + spaceAround)
  }|${
    '-' * (maxNameLength + spaceAround)
  }|${
    '-' * (maxValueLength + spaceAround)
  }|${
    '-' * (maxCodeLength + spaceAround)
  }|$reset\n");

  
  // build table body
  for (final row in table) {
    sb.write("$tableColor|$reset$sideSpace${
      row.color.padRight(maxColorLength + (row.color.length - colorBlock))
    }$sideSpace$tableColor|$reset$sideSpace$nameColor${
      row.name.padRight(maxNameLength)
    }$sideSpace$tableColor|$reset$sideSpace$valueColor${
      row.value.padRight(maxValueLength)
    }$sideSpace$tableColor|$reset$sideSpace$codeColor${
      row.code.padRight(maxCodeLength)
    }$sideSpace$tableColor|$reset\n");
  }

  // print table
  print(sb.toString());
}

void printColorLiterals() {
  final EvalList map = List.generate(LITERALS.colorLiterals.length,
    (i) {
      final lit = LITERALS.colorLiterals[i];
      return (lit.$1, IntValue(lit.$2));
    },
    growable:  false
  );
  
  printEval(map);
}