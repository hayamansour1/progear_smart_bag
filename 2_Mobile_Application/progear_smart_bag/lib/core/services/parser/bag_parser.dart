import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:progear_smart_bag/core/debug/debug_flags.dart';

/// BagParser
class BagParser {
  final StreamController<String> _linesCtrl =
      StreamController<String>.broadcast();

  Stream<String> get stream => _linesCtrl.stream;

  StreamSubscription<List<int>>? _sub;

  String _buffer = '';

  Future<void> bind(BluetoothCharacteristic characteristic) async {
    await _sub?.cancel();

    DebugFlags.logParser(
        '🧩 BagParser.bind: enabling notify on ${characteristic.uuid}');
    await characteristic.setNotifyValue(true);

    _sub = characteristic.onValueReceived.listen(
      (bytes) {
        DebugFlags.logParser('🧩 RAW BLE BYTES: $bytes');
        if (bytes.isEmpty) return;

        final chunk = utf8.decode(bytes, allowMalformed: true);
        DebugFlags.logParser('🧩 RAW BLE TEXT CHUNK: $chunk');

        _buffer += chunk;

        int newlineIndex;
        while ((newlineIndex = _buffer.indexOf('\n')) != -1) {
          final line = _buffer.substring(0, newlineIndex).trim();
          _buffer = _buffer.substring(newlineIndex + 1);

          if (line.isNotEmpty) {
            DebugFlags.logParser('🧩 PARSED BLE LINE: $line');
            _linesCtrl.add(line);
          }
        }
      },
      onError: (e) {
        DebugFlags.logParser('BagParser error: $e');
      },
      cancelOnError: false,
    );
  }

  Future<void> unbind() async {
    await _sub?.cancel();
    _sub = null;
    _buffer = '';
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _linesCtrl.close();
    _buffer = '';
  }
}
