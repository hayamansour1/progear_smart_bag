import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/app_keys.dart';

enum ToastStyle { success, info, warn, error }

class ProGearToast {
  static void show(
    String message, {
    ToastStyle style = ToastStyle.success,
    IconData? icon,
    Duration? duration,
  }) {
    final messenger = rootMessengerKey.currentState;
    if (messenger == null) return;

    Color bg;
    IconData ic;
    switch (style) {
      case ToastStyle.success:
        bg = const Color(0xFF159B00);
        ic = Icons.check_rounded;
        break;
      case ToastStyle.info:
        bg = const Color(0xFF2667FF);
        ic = Icons.info_rounded;
        break;
      case ToastStyle.warn:
        bg = const Color(0xFFFFAA00);
        ic = Icons.warning_rounded;
        break;
      case ToastStyle.error:
        bg = const Color(0xFFDD0000);
        ic = Icons.error_rounded;
        break;
    }

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg.withValues(alpha: 0.95),
        duration: duration ?? const Duration(milliseconds: 1500),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        shape: const StadiumBorder(),
        elevation: 0,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? ic, size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
