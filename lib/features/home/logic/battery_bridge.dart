// lib/features/home/logic/battery_bridge.dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'battery_controller.dart';
import 'package:progear_smart_bag/features/activity/data/last_controller_store.dart';

class BatteryBridge {
  /// يربط البطارية مع الـ BLE
  static Future<void> bind(
    BatteryController ctrl,
    BluetoothCharacteristic ch, {
    required String controllerID,
  }) async {
    ctrl.setControllerID(controllerID);

    // 👇 نعتمد على قراءات BLE مباشرة، بدون boot من الـ DB هنا
    await ctrl.bindToCharacteristic(ch);

    // نحدّث آخر controllerID محلياً (للأوفلاين لو احتجناه)
    await LastControllerStore.instance.setLastControllerID(controllerID);
  }

  /// boot من آخر شنطة محفوظة (بدون BLE) — للأوفلاين فقط
  static Future<void> bootFromLastController(BatteryController ctrl) async {
    final lastId = await LastControllerStore.instance.getLastControllerID();
    if (lastId == null || lastId.isEmpty) return;
    ctrl.setControllerID(lastId);
    await ctrl.boot();
  }

  /// فك الربط عن الـ BLE (نخلي آخر قراءة موجودة للأوفلاين)
  static Future<void> unbind(BatteryController ctrl) async {
    await ctrl.unbind();
  }
}
