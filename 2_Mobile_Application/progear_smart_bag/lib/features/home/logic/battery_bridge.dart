// lib/features/home/logic/battery_bridge.dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'battery_controller.dart';
import 'package:progear_smart_bag/features/activity/data/last_controller_store.dart';

class BatteryBridge {
  /// Connects the battery to BLE
  static Future<void> bind(
    BatteryController ctrl,
    BluetoothCharacteristic ch, {
    required String controllerID,
  }) async {
    ctrl.setControllerID(controllerID);

    // We rely on BLE readings directly, without booting from the DB here
    await ctrl.bindToCharacteristic(ch);

    // Update the last controllerID locally (for offline use if needed)
    await LastControllerStore.instance.setLastControllerID(controllerID);
  }

  /// Boot from the last saved bag (without BLE) — for offline use only
  static Future<void> bootFromLastController(BatteryController ctrl) async {
    final lastId = await LastControllerStore.instance.getLastControllerID();
    if (lastId == null || lastId.isEmpty) return;
    ctrl.setControllerID(lastId);
    await ctrl.boot();
  }

  /// Unbind from BLE (keep the last reading for offline use)
  static Future<void> unbind(BatteryController ctrl) async {
    await ctrl.unbind();
  }
}
