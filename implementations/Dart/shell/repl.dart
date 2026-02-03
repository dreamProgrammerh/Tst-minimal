import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../utils/rawmode.dart';

typedef ReplListener = void Function(List<int> bytes, List<int> buffer, bool flush);

late Timer _cancelTimer;
bool _waitingForSecond = false;
StreamSubscription<List<int>>? _sub;

final List<String> _history = [];
List<int> _line = [];
int _cursor = 0;
int _historyIndex = -1; // -1 means “not browsing history”

String _prompt = "> ";
bool _lastWasCR = false;
bool _flush = false;
int _escState = 0; // 0 = normal, 1 = ESC, 2 = ESC [
int _escParam = 0; // for keys like 2~, 3~
int _escMod = 0;
bool _insertMode = false;

bool _searchMode = false;
String _savedLine = '';
int _savedCursor = 0;

bool isRunning = false;

void start(ReplListener listener, {
  bool raw = false,
  String prompt = "> "}) {
  _prompt = prompt;

  isRunning = true;
  setRawMode(raw: true);

  _write(_prompt);
  _sub = stdin.listen((bytes) {
    if (!isRunning) return;

    if (!raw) _handleBytes(bytes);
    final flush = raw || _flush;

    listener(bytes, _line, flush);
    if (flush && isRunning) _clearLine();
  });
}

void cancel() {
  _sub?.cancel();
  isRunning = false;
}

void pasue() {
  _sub?.pause();
  isRunning = false;
}

void resume() {
  _sub?.resume();
  isRunning = true;
}

void changePrompt(String prompt) {
  _prompt = prompt;
}

void _write(Object object) {
  stdout.write(object);
}

void _handleBytes(List<int> bytes) {
  // _write(bytes);
  _lastWasCR = false;
  _flush = false;
  _escState = 0;

  if (bytes.length == 1 && bytes[0] == 27) {
    _onESC();
    return;
  }

  for (var b in bytes) {
    // Escaped characters (arrows, Home, End, etc.)
    if (_handleEscape(b)) continue;

    // Visual chars (ASCII, backspace, linefeed, etc.)
    if (_handleNormalByte(b)) continue;

    // Control keys (Ctrl+Q, Ctrl+C, etc.)
    _handleControlByte(b);
  }
}

bool _handleEscape(int b) {
  // State 0: waiting for ESC
  if (_escState == 0) {
    if (b == 27) { // ESC
      _escState = 1;
      return true;
    }
    return false;
  }

  // State 1: ESC received
  if (_escState == 1) {
    if (b == 100) { // Alt+D & Ctrl+Delete
      _onCtrlDelete();
      _escState = 0;
      return true;
    }
    if (b == 91) { // '['
      _escState = 2;
      return true;
    }
    _escState = 0;
    return false;
  }

  // State 2: ESC [ received
  if (_escState == 2) {
    // Arrow keys: A B C D
    if (b == 65) { _onArrowUp();    _escState = 0; return true; }
    if (b == 66) { _onArrowDown();  _escState = 0; return true; }
    if (b == 67) { _onArrowRight(); _escState = 0; return true; }
    if (b == 68) { _onArrowLeft();  _escState = 0; return true; }

    // Home / End
    if (b == 72) { _onHome(); _escState = 0; return true; }
    if (b == 70) { _onEnd();  _escState = 0; return true; }

    // Start of multi‑byte keys: Insert/Delete
    if (b >= 48 && b <= 57) { // digits
      _escParam = b - 48;     // store digit
      _escState = 3;
      return true;
    }

    _escState = 0;
    return false;
  }

  // State 3: ESC [ <digit>
  if (_escState == 3) {
    if (b == 126) { // '~'
      if (_escParam == 2) _onInsert();
      if (_escParam == 3) _onDelete();
    }
    if (b == 59) { // ';'
      _escState = 4;
      return true;
    }
    _escState = 0;
    return true;
  }

  if (_escState == 4 && b >= 48 && b <= 57) {
    _escMod = b - 48;
    _escState = 5;
    return true;
  }

  if (_escState == 5) {
    if (_escParam == 1 && _escMod == 5) {
      if (b == 68) _onCtrlLeft();
      if (b == 67) _onCtrlRight();
    }
    _escState = 0;
    return true;
  }

  _escState = 0;
  return false;
}

bool _handleNormalByte(int b) {
  // Windows CRLF handling
  if (_lastWasCR && b == 10) {
    _lastWasCR = false;
    // Already handled CR as Enter, so skip LF
    return true;
  }

  // CR (Windows Enter)
  if (b == 13) {
    _lastWasCR = true;
    _onLine();
    return true;
  }

  // LF (Unix Enter or Ctrl/Shift+Enter on Windows)
  if (b == 10) {
    _onLine();
    return true;
  }

  // BACKSPACE (Windows = 8, Unix = 127)
  if (b == 8 || b == 127) {
    _onBackspace();
    return true;
  }

  // Printable ASCII
  if (b >= 32 && b <= 126) {
    _insertChar(b);
    return true;
  }

  return false;
}

void _handleControlByte(int byte) {
  if (byte == 3) { // Ctrl+C
    _break();
    return;
  }
  if (byte == 17) { // Ctrl+Q
    _quit();
    return;
  }
  if (byte == 18) { // Ctrl+R
    _onCtrlR();
    return;
  }
  if (byte == 23) { // Ctrl+W & Ctrl+Backspace
    _onCtrlBackspace();
    return;
  }
  if (byte == 12) { // Ctrl+L
    _clearScreen();
    return;
  }
  if (byte == 1) { // Ctrl+A
    _onHome();
    return;
  }
  if (byte == 5) { // Ctrl+E
    _onEnd();
    return;
  }
}


void _exit() {
  exit(0);
}

void _quit() {
  isRunning = false;
  setRawMode(raw: false);
  _exit();
}

void _break() {
  const msg = "press ctrl+c again to exit... (\$)\r";

  if (_searchMode) {
    _cancelSearch();
    return;
  }

  if (!_waitingForSecond) {
    _waitingForSecond = true;
    int remaining = 3;

    _write('\n');
    _write(msg.replaceFirst('\$', '$remaining', msg.length - 3));
    _cancelTimer = Timer.periodic(Duration(seconds: 1), (t) {
      remaining--;
      if (remaining > 0) {
        _write(msg.replaceFirst('\$', '$remaining', msg.length - 3));

      } else {
        t.cancel();
        _waitingForSecond = false;

        // Clear the line
        _write(" " * (msg.length) + "\r");
        _write(_prompt);
      }
    });

    return;
  }

  // Clear & Exit
  _cancelTimer.cancel();
  _write(" " * (msg.length) + "\r");
  _exit();
}

void _insertChar(int b) {
  if (_insertMode && _cursor < _line.length) {
    _line[_cursor++] = b; // overwrite
    _write(String.fromCharCode(b));
    
  } else {
    // normal insert mode
    _line.insert(_cursor, b);
    _cursor++;
  
    final tail = utf8.decode(_line.sublist(_cursor));
    _write(String.fromCharCode(b) + tail);
  
    if (tail.isNotEmpty) {
      _write('\x1B[${tail.length}D');
    }
  }
  
  if (_searchMode)
    _updateSearchUI();
}

void _clearScreen() {
  // Clear Screen and Move cursor to home
  _write('\x1B[2J\x1B[H');
  _write(_prompt);

  _line.clear();
  _cursor = 0;
}

void _clearLine() {
  // Move cursor to start and Clear line
  _write('\r\x1B[2K');
  _write(_prompt);

  _line.clear();
  _cursor = 0;
}

void _loadHistoryEntry() {
  _clearLine();
  final entry = _history[_historyIndex];
  _line = List.from(entry.codeUnits);
  _cursor = _line.length;
  _write(entry);
}

String _findBestMatch(String query) {
  if (query.isEmpty) return '';

  for (int i = _history.length - 1; i > -1; i--) {
    if (_history[i].contains(query))
      return _history[i];
  }

  return '';
}

void _acceptSearch() {
  final query = utf8.decode(_line);
  final match = _findBestMatch(query);

  _searchMode = false;

  if (match.isNotEmpty) {
    _line = List.from(match.codeUnits);
    _cursor = _line.length;
  } else {
    _line.clear();
    _cursor = 0;
  }

  _clearSearchUI();
  _redrawLine();
}

void _cancelSearch() {
  _searchMode = false;

  _line = List.from(_savedLine.codeUnits);
  _cursor = _savedCursor;

  _clearSearchUI();
  _redrawLine();
}

void _showSearchResult() {
  final query = utf8.decode(_line);
  final match = _findBestMatch(query);

  // Move to next line
  _write('\n\x1B[2K');

  if (match.isEmpty) {
    _write("\x1B[90m- no match -\x1B[0m");
  } else {
    _write('\x1B[30m$match\x1B[0m');
  }

  // Move back to search line
  _write('\x1B[A');
  _redrawLine();
}

void _showSearchHeader() {
  _write("\r\x1B[2K[ Search Mode - press ESC to exit ]\n");
}

void _clearSearchHeader() {
  _write(
    '\x1B[A'    // back to header
    '\r\x1B[2K' // clear header
  );
}

void _updateSearchUI() {
  _clearSearchHeader();  // wipe old header
  _showSearchHeader();   // print header
  _redrawLine();         // print query
  _showSearchResult();   // print result
}

void _clearSearchUI() {
  _write(
    '\r\x1B[2K' // clear search input
    '\n\x1B[2K' // go down clear match
    '\x1B[2A'   // back to header
    '\r\x1B[2K' // clear header
  );
}

void _redrawLine() {
  // Move to start of line and Clear entire line
  _write('\r\x1B[2K');

  // Write prompt
  _write(_prompt);

  // Write full line buffer
  final text = utf8.decode(_line);
  _write(text);

  // Move cursor to correct position
  final moveBack = _line.length - _cursor;
  if (moveBack > 0) {
    _write('\x1B[${moveBack}D');
  }
}

void _redrawCursor() {
  _write('\r$_prompt');
  _write(utf8.decode(_line));

  final moveBack = _line.length - _cursor;
  if (moveBack > 0) {
    _write('\x1B[${moveBack}D');
  }
}

void _onBackspace() {
  if (_cursor == 0) return;

  _cursor--;
  _line.removeAt(_cursor);

  // Move cursor left
  _write('\x1B[D');

  // Rewrite tail
  final tail = utf8.decode(_line.sublist(_cursor));
  _write(tail + ' ');

  // Move cursor back
  final moveBack = tail.length + 1;
  _write('\x1B[${moveBack}D');
  
  if (_searchMode)
    _updateSearchUI();
}

void _onLine() {
  if (_searchMode) {
    _acceptSearch();
    return;
  }

  final text = utf8.decode(_line).trim();
  _cursor = 0;

  if (text.isNotEmpty && (_history.isEmpty || _history.last != text))
    _history.add(text);

  _historyIndex = -1;

  _write('\n');
  _flush = true;
}

void _onESC() {
  if (_searchMode) {
    _cancelSearch();
  }
}

void _onArrowUp() {
  if (_history.isEmpty) return;

  if (_historyIndex == -1) {
    _historyIndex = _history.length - 1;
  } else if (_historyIndex > 0) {
    _historyIndex--;
  }

  _loadHistoryEntry();
}

void _onArrowDown() {
  if (_history.isEmpty) return;

  if (_historyIndex == -1) return; // already at newest

  _historyIndex++;

  if (_historyIndex >= _history.length) {
    _historyIndex = -1;
    _clearLine();
    return;
  }

  _loadHistoryEntry();
}

void _onArrowRight() {
  if (_cursor < _line.length) {
    _cursor++;
    _write('\x1B[C'); // move cursor right
  }
}

void _onArrowLeft() {
  if (_cursor > 0) {
    _cursor--;
    _write('\x1B[D'); // move cursor left
  }
}

void _onHome() {
  if (_cursor > 0) {
    _write('\x1B[${_cursor}D'); // move left N times
    _cursor = 0;
  }
}

void _onEnd() {
  final move = _line.length - _cursor;
  if (move > 0) {
    _write('\x1B[${move}C'); // move right N times
    _cursor = _line.length;
  }
}

void _onInsert() {
  _insertMode = !_insertMode;
}

void _onDelete() {
  if (_cursor >= _line.length) return;

  _line.removeAt(_cursor);

  // Rewrite tail
  final tail = utf8.decode(_line.sublist(_cursor));
  _write(tail + ' ');

  // Move cursor back
  _write('\x1B[${tail.length + 1}D');
  
  if (_searchMode)
    _updateSearchUI();
}

void _onCtrlRight() {
  if (_cursor >= _line.length) return;

  // Skip current word
  while (_cursor < _line.length && _line[_cursor] != 32) {
    _cursor++;
  }

  // Skip spaces
  while (_cursor < _line.length && _line[_cursor] == 32) {
    _cursor++;
  }

  _redrawCursor();
}

void _onCtrlLeft() {
  if (_cursor == 0) return;

  // Skip spaces
  while (_cursor > 0 && _line[_cursor - 1] == 32) {
    _cursor--;
  }

  // Skip word characters
  while (_cursor > 0 && _line[_cursor - 1] != 32) {
    _cursor--;
  }

  _redrawCursor();
}

void _onCtrlBackspace() {
  if (_cursor == 0) return;

  int start = _cursor;

  // Skip spaces
  while (start > 0 && _line[start - 1] == 32) start--;

  // Skip word
  while (start > 0 && _line[start - 1] != 32) start--;

  _line.removeRange(start, _cursor);
  _cursor = start;

  
  if (_searchMode)
    _updateSearchUI();
    
  else 
    _redrawLine();
}

void _onCtrlDelete() {
  if (_cursor >= _line.length) return;

  int end = _cursor;

  // Skip spaces
  while (end < _line.length && _line[end] == 32) end++;

  // Skip word
  while (end < _line.length && _line[end] != 32) end++;

  _line.removeRange(_cursor, end);

  if (_searchMode)
    _updateSearchUI();
    
  else 
    _redrawLine();
}

void _onCtrlR() {
  if (_searchMode) {
    _cancelSearch();
    return;
  }
  
  _searchMode = true;

  _savedLine = utf8.decode(_line);
  _savedCursor = _cursor;

  _line.clear();
  _cursor = 0;

  _showSearchHeader();
  _redrawLine();
  _showSearchResult();
}
