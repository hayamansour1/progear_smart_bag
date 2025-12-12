import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/features/home/logic/battery_controller.dart';
import 'package:progear_smart_bag/features/weight/logic/weight_controller.dart';

import 'missing_alert_card.dart';
import 'battery_card.dart';

class TwoUpCards extends StatelessWidget {
  const TwoUpCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ============ MISSING ALERT CARD ============
        Expanded(
          child: Consumer<WeightController>(
            builder: (_, weightCtrl, __) {
              final expected = weightCtrl.expectedG;
              final current = weightCtrl.currentG;

              BagStatus status;

              if (expected <= 0) {
                status = BagStatus.ok;
              } else if (current < expected - 100) {
                status = BagStatus.missing;
              } else if (current > expected + 100) {
                status = BagStatus.extra;
              } else {
                status = BagStatus.ok;
              }

              return MissingAlertCard(status: status);
            },
          ),
        ),

        const SizedBox(width: AppSizes.lg),

        // ============ BATTERY CARD ============
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
