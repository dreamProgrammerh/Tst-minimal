bool isWhitespace(String c) {
  return ' \t\v\r\n\b\f'.contains(c);
}

List<String> splitString(String input) {
  final tokens = <String>[];
  final token = StringBuffer();
  bool insideQuotes = false;

  for (int i = 0; i < input.length; i++) {
    final c = input[i];

    if (c == '\"' || c == '\'') {
      insideQuotes = !insideQuotes;
      if (!insideQuotes) {
        tokens.add(token.toString());
        token.clear();
      }
      
    } else if (isWhitespace(c) && !insideQuotes) {
      if (token.isNotEmpty) {
        tokens.add(token.toString());
        token.clear();
      }
    
    } else {
      token.write(c);
    }

  }

  if (token.isNotEmpty)
    tokens.add(token.toString());

  return tokens;
}

String toTitleCase(String str) {
  final words = str.split(" ");
  final titleCase = new StringBuffer();
  
  for (final word in words) {
    if (word.isNotEmpty) {
      titleCase.write('${
        word[0].toUpperCase}${
        word.substring(1).toLowerCase()} ');
    }
  }
  
  return titleCase.toString().trim();
}

String toSnakeCase(String str) {
  return str.toLowerCase().replaceAll(" ", "_");
}

String toCamelCase(String str) {
  final words = str.split(" ");
  final camelCase = new StringBuffer(words[0].toLowerCase());
  
  for (int i = 1; i < words.length; i++) {
    if (words[i].isNotEmpty) {
      camelCase.write('${
        words[i][0].toUpperCase()}${
        words[i].substring(1).toLowerCase()}');
    }
  }
  
  return camelCase.toString();
}

String capitalizeSentences(String str) {
  final sentences = str.trim().split(RegExp(r"(?<=[.!?])\s*"));
  final result = new StringBuffer();
  
  for (final sentence in sentences) {
    if (sentence.isNotEmpty) {
      result.write('${
        sentence[0].toUpperCase()}${
        sentence.substring(1).toLowerCase()} ');
    }
  }

  return result.toString();
}
