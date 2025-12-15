// lib/features/weight/logic/weight_bridge.dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'weight_controller.dart';
import 'package:progear_smart_bag/features/activity/data/last_controller_store.dart';

class WeightBridge {
  static Future<void> bind(
    WeightController ctrl,
    BluetoothCharacteristic ch, {
    required String controllerID,
  }) async {
    await ctrl.boot(controllerID: controllerID);

    await ctrl.bindToCharacteristic(
      ch,
      controllerID: controllerID,
    );
  }

  static Future<void> bootFromLastController(WeightController ctrl) async {
    final lastId = await LastControllerStore.instance.getLastControllerID();
    if (lastId == null || lastId.isEmpty) return;
    await ctrl.boot(controllerID: lastId);
  }

  static Future<void> unbind(WeightController ctrl) async {
    await ctrl.unbind();
  }
}
