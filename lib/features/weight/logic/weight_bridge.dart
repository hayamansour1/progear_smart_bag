import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:progear_smart_bag/features/weight/logic/weight_controller.dart';

class WeightBridge {
  static BuildContext? _ctx;

  static void attachContext(BuildContext context) {
    _ctx = context;
  }

  static void detachContext() {
    _ctx = null;
  }

  static Future<void> bind(BluetoothCharacteristic ch) async {
    final ctx = _ctx;
    if (ctx == null) return;
    final ctrl = ctx.read<WeightController>();
    await ctrl.bindToCharacteristic(ch);
  }

  static Future<void> unbind() async {
    final ctx = _ctx;
    if (ctx == null) return;
    final ctrl = ctx.read<WeightController>();
    await ctrl.unbind();
  }
}
