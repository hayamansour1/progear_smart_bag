// lib/features/weight/logic/weight_bridge.dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'weight_controller.dart';

class WeightBridge {
  /// يربط الكنترولر مع الـ BLE + يحمل الـ snapshot من الـ DB
  static Future<void> bind(
    WeightController ctrl,
    BluetoothCharacteristic ch, {
    required String controllerID,
  }) async {
    // يجيب آخر حالة من الـ DB
    await ctrl.boot(controllerID: controllerID);

    // يربط الـ stream
    await ctrl.bindToCharacteristic(
      ch,
      controllerID: controllerID,
    );
  }

  /// فك الربط عن الـ BLE
  static Future<void> unbind(WeightController ctrl) async {
    await ctrl.unbind();
  }
}
