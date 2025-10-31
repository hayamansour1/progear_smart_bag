// lib/features/home/logic/battery_bridge.dart
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:progear_smart_bag/features/home/logic/battery_controller.dart';

/// BatteryBridge: simple static hook so BLE layer can bind/unbind easily.
class BatteryBridge {
  static BuildContext? _ctx;

  /// Call once after Providers are built (in main.dart)
  static void attachContext(BuildContext context) {
    _ctx = context;
  }

  /// Call from ProGearApp.dispose()
  static void detachContext() {
    _ctx = null;
  }

  /// Called by Bluetooth side when the correct characteristic is found.
  static Future<void> bind(BluetoothCharacteristic ch) async {
    final ctx = _ctx;
    if (ctx == null) return;
    final ctrl = ctx.read<BatteryController>();
    await ctrl.bindToCharacteristic(ch);
  }

  /// Called by Bluetooth side on disconnect.
  static Future<void> unbind() async {
    final ctx = _ctx;
    if (ctx == null) return;
    final ctrl = ctx.read<BatteryController>();
    await ctrl.unbind();
  }
}
