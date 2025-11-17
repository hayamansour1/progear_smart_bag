import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:progear_smart_bag/features/weight/logic/weight_controller.dart';

class WeightBridge {
  static Future<void> bind(BuildContext context, BluetoothCharacteristic ch,
      {required String controllerID}) async {
    final ctrl = context.read<WeightController>();
    await ctrl.bindToCharacteristic(ch, controllerID: controllerID);
  }

  /// TODO Call Bind Widgh
  static Future<void> unbind(BuildContext context) async {
    final ctrl = context.read<WeightController>();
    await ctrl.unbind();
  }
}
