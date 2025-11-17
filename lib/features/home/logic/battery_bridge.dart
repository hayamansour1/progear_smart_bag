// lib/features/home/logic/battery_bridge.dart
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:progear_smart_bag/features/home/logic/battery_controller.dart';

/// BatteryBridge: simple static hook so BLE layer can bind/unbind easily.
class BatteryBridge {
  /// Called by Bluetooth side when the correct characteristic is found.
  static Future<void> bind(
      BuildContext context, BluetoothCharacteristic ch) async {
    final ctrl = context.read<BatteryController>();
    await ctrl.bindToCharacteristic(ch);
  }

  /// Called by Bluetooth side on disconnect.
  static Future<void> unbind(BuildContext context) async {
    final ctrl = context.read<BatteryController>();
    await ctrl.unbind();
  }
}
