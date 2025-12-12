import 'package:flutter/foundation.dart';

/// DebugFlags:
// False positives are okay here since this is only for debugging.
class DebugFlags {
  static const bool bleVerbose = true;
  static const bool parserVerbose = true;
  static const bool weightVerbose = true;
  static const bool batteryVerbose = true;

  static void logBle(String msg) {
    if (!bleVerbose || !kDebugMode) return;
    debugPrint(msg);
  }

  static void logParser(String msg) {
    if (!parserVerbose || !kDebugMode) return;
    debugPrint(msg);
  }

  static void logWeight(String msg) {
    if (!weightVerbose || !kDebugMode) return;
    debugPrint(msg);
  }

  static void logBattery(String msg) {
    if (!batteryVerbose || !kDebugMode) return;
    debugPrint(msg);
  }
}
