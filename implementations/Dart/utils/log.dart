import '../runtime/context.dart';
import '../runtime/values.dart';
import 'colors.dart';

class _TableRow {
  String color;
  String name;
  String value;
  String rep;
  
  _TableRow({
    this.color  = '',
    this.name   = '',
    this.value  = '',
    this.rep    = '',
  });
  
  @override
  String toString() {
    return '($color, $name, $value, $rep)';
  }
}

int _max(int a, int b) {
  return a > b ? a : b;
}

void printEvalMap(EvalMap map) {
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
    representationColor = "\x1B[36m",
    
    sideSpace = ' ' * (spaceAround ~/ 2),
    colorTitle = "Color",
    nameTitle = "Name",
    valueTitle = "Value",
    representationTitle = "Representation";

  // columns length
  int
    maxColorLength = _max(colorBlock, colorTitle.length),
    maxNameLength = _max(10, nameTitle.length),
    maxValueLength = _max(12, valueTitle.length),
    maxRepresentationLength = _max(14, representationTitle.length);

  
  // organize the table
  List<_TableRow> table = List.generate(map.length,
    (_) => new _TableRow(
      color: '',
      name: '',
      value: '',
      rep: ''
    ), growable: false);
  
  // fill table with data
  int i = 0;
  for (final entry in map.entries) {
    _TableRow row = table[i++];
    // name column
    row.name = entry.key;
    
    // value column
    row.value = entry.value is IntValue
      ? (entry.value as IntValue).value.toString()
      : entry.value is FloatValue
        ? (entry.value as FloatValue).value.toString()
        : "invalid";
    
    // color column
    if (entry.value is IntValue) {
      final v = entry.value as IntValue;
      row.color = '\x1B[7m${ansiColoredText(' ' * colorBlock, v.value)}';
    } else {
      row.color = ' ' * colorBlock;
    }
    
    // color column
    row.rep = entry.value is IntValue
      ? '#${(entry.value as IntValue).value.toRadixString(16).padRight(8, '0').toUpperCase()}'
      : entry.value is FloatValue
        ? '${(entry.value as FloatValue).value.toStringAsExponential()}f'
        : '';
  
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
    representationTitle.padRight(maxRepresentationLength)
  }$sideSpace|$reset\n");
  
  sb.write("$tableColor|${
    '-' * (maxColorLength + spaceAround)
  }|${
    '-' * (maxNameLength + spaceAround)
  }|${
    '-' * (maxValueLength + spaceAround)
  }|${
    '-' * (maxRepresentationLength + spaceAround)
  }|$reset\n");

  
  // build table body
  for (final row in table) {
    sb.write("$tableColor|$reset$sideSpace${
      row.color.padRight(maxColorLength + (row.color.length - colorBlock))
    }$sideSpace$tableColor|$reset$sideSpace$nameColor${
      row.name.padRight(maxNameLength)
    }$sideSpace$tableColor|$reset$sideSpace$valueColor${
      row.value.padRight(maxValueLength)
    }$sideSpace$tableColor|$reset$sideSpace$representationColor${
      row.rep.padRight(maxRepresentationLength)
    }$sideSpace$tableColor|$reset\n");
  }

  // print table
  print(sb.toString());
}
