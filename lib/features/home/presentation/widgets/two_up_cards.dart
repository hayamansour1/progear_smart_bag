import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/features/home/logic/battery_controller.dart';
import 'package:provider/provider.dart';
import 'missing_alert_card.dart';
import 'battery_card.dart';

// When you’re ready to use live data, uncomment Provider imports:
// import 'package:provider/provider.dart';
// import 'package:progear_smart_bag/features/home/logic/battery_controller.dart';

class TwoUpCards extends StatelessWidget {
  const TwoUpCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: MissingAlertCard()),
        const SizedBox(width: AppSizes.lg),

        // ---- TEMP: show a fake battery card while BLE wiring is pending ----
        // const Expanded(
        //   child: BatteryCard(
        //     percent: 76,
        //     isCharging: true,
        //     // lastUpdated: DateTime(2025, 10, 18, 18, 02),
        //   ),
        // ),

        // ---- REAL (uncomment this block when BatteryController is wired) ----

        Expanded(
          child: Consumer<BatteryController>(
            builder: (_, controller, __) {
              return BatteryCard(
                percent: controller.percent,
                isCharging: controller.isCharging,
                lastUpdated: controller.lastUpdated,
              );
            },
          ),
        ),
      ],
    );
  }
}
