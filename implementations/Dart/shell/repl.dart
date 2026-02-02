import 'dart:async';
import 'dart:io';

import '../utils/rawmode.dart';

typedef ReplListener = void Function(List<int> bytes, List<int> buffer, bool flush);

final List<int> _bytesBuffer = [];
late Timer _cancelTimer;
bool _waitingForSecond = false;
StreamSubscription<List<int>>? _sub;
late ReplListener _listener;

bool isRunning = false;

void start(ReplListener listener, {bool raw = false}) {
  _listener = listener;
  isRunning = true;
  setRawMode(raw: true);

  _sub = stdin.listen((bytes) {
    if (!isRunning) return;

    final flush = raw || _handleBytes(bytes);
    listener(bytes, _bytesBuffer, flush);

    if (flush) _bytesBuffer.clear();
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

void _write(Object object) {
  stdout.write(object);
}

bool _handleBytes(List<int> bytes) {
  _write(bytes);
  bool flush = false;
  bool lastWasCR = false;

  for (var b in bytes) {
    // Windows CRLF handling
    if (lastWasCR && b == 10) {
      lastWasCR = false;
      // Already handled CR as Enter, so skip LF
      continue;
    }

    // CR (Windows Enter)
    if (b == 13) {
      lastWasCR = true;
      flush = true;
      _write('\n');
      continue;
    }

    // LF (Unix Enter or Ctrl/Shift+Enter on Windows)
    if (b == 10) {
      flush = true;
      _write('\n');
      continue;
    }

    // BACKSPACE (Windows = 8, Unix = 127)
    if (b == 8 || b == 127) {
      if (_bytesBuffer.isNotEmpty) {
        _bytesBuffer.removeLast();
        // erase last char visually
        _write('\b \b');
      }
      continue;
    }

    // Printable ASCII
    if (b >= 32 && b <= 126) {
      _bytesBuffer.add(b);
      _write(String.fromCharCode(b));
      continue;
    }

    // Control keys (Ctrl+Q, Ctrl+C, arrows, etc.)
    _handleControlByte(b);
  }

  return flush;
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

        // Update the listener
        _listener([], [], true);
      }
    });

    return;
  }

  // Exit
  _cancelTimer.cancel();
  _exit();
}
