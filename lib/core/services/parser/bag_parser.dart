import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BagParser
/// Handles plain-text BLE data and emits clean text lines.
class BagParser {
  final StreamController<String> _linesCtrl =
      StreamController<String>.broadcast();
  // call stream from outside to listen
  Stream<String> get stream => _linesCtrl.stream;

  StreamSubscription<List<int>>? _sub;
  // Rx buffer storage data until full line
  String _rxBuffer = '';

  /// Bind BLE notify characteristic and convert bytes --> text lines.
  Future<void> bind(BluetoothCharacteristic characteristic) async {
    await _sub?.cancel();
    _rxBuffer = '';

    await characteristic.setNotifyValue(true);

    _sub = characteristic.lastValueStream.listen((bytes) {
      if (bytes.isEmpty) return;

      final chunk = utf8.decode(bytes, allowMalformed: true);
      _rxBuffer += chunk;

      final parts = _rxBuffer.split(RegExp(r'[\r\n]+'));
      _rxBuffer = parts.isNotEmpty ? parts.removeLast() : '';

      for (final raw in parts) {
        final line = raw.trim();
        if (line.isNotEmpty) _linesCtrl.add(line);
      }
    }, onError: (e) {
      debugPrint('BagParser error: $e');
    }, cancelOnError: false);
  }

  Future<void> unbind() async {
    await _sub?.cancel();
    _sub = null;
    _rxBuffer = '';
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _linesCtrl.close();
  }
}
