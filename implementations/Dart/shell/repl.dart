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

  for (var b in bytes) {
    // Escape Char
    if (_handleEscape(b)) continue;
    
    // Printable, backspace, linefeed, etc.
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

  // State 1: ESC received, expecting '['
  if (_escState == 1) {
    if (b == 91) { // '['
      _escState = 2;
      return true;
    }
    _escState = 0;
    return false;
  }

  // State 2: ESC [ received, expecting final code
  if (_escState == 2) {
    if (b == 65) _onArrowUp();
    else if (b == 66) _onArrowDown();
    else if (b == 67) _onArrowRight();
    else if (b == 68) _onArrowLeft();

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
    _flushLine();
    return true;
  }

  // LF (Unix Enter or Ctrl/Shift+Enter on Windows)
  if (b == 10) {
    _flushLine();
    return true;
  }

  // BACKSPACE (Windows = 8, Unix = 127)
  if (b == 8 || b == 127) {
    _handleBackspace();
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

  } else
  if (byte == 17) { // Ctrl+Q
    _quit();
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

void _insertChar(int byte) {
  _line.insert(_cursor, byte);
  _cursor++;

  // Rewrite the rest of the line
  final tail = utf8.decode(_line.sublist(_cursor));
  _write(String.fromCharCode(byte) + tail);

  // Move cursor back to correct position
  final moveBack = tail.length;
  if (moveBack > 0) {
    _write('\x1B[${moveBack}D');
  }
}

void _clearLine() {
  // Move cursor to start and Clear line
  _write('\r\x1B[2K');
  _write(_prompt);

  _line.clear();
  _cursor = 0;
}

void _handleBackspace() {
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
}

void _flushLine() {
  final text = utf8.decode(_line).trim();
  _cursor = 0;

  if (text.isNotEmpty && (_history.isEmpty || _history.last != text))
    _history.add(text);
  
  _historyIndex = -1;

  _write('\n');
  _flush = true;
}

void _loadHistoryEntry() {
  _clearLine();
  final entry = _history[_historyIndex];
  _line = List.from(entry.codeUnits);
  _cursor = _line.length;
  _write(entry);
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