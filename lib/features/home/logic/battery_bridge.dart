// lib/features/home/logic/battery_bridge.dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'battery_controller.dart';

/// BatteryBridge: جسر بسيط بين BLE و BatteryController بدون BuildContext.
class BatteryBridge {
  /// يربط الكنترولر مع الـ BLE + يحدد controllerID + يحمل من الـ DB
  static Future<void> bind(
    BatteryController ctrl,
    BluetoothCharacteristic ch, {
    required String controllerID,
  }) async {
    // نخزن الـ controllerID داخل الكنترولر
    ctrl.setControllerID(controllerID);

    // نجيب آخر حالة من الـ DB (لو فيه repo)
    await ctrl.boot();

    // نربط الـ BLE stream
    await ctrl.bindToCharacteristic(ch);
  }

  /// فك الربط عن الـ BLE + تصفير الحالة عشان ما تنتقل ليوزر جديد
  static Future<void> unbind(BatteryController ctrl) async {
    await ctrl.unbind();
    ctrl.resetState(); // ⬅️ هذي الإضافة الوحيدة
  }
}
