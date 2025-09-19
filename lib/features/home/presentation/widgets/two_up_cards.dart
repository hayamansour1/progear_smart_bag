import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'missing_alert_card.dart';
import 'battery_card.dart';

class TwoUpCards extends StatelessWidget {
  const TwoUpCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: MissingAlertCard()),
        SizedBox(width: AppSizes.lg),
        Expanded(child: BatteryCard(percent: 30)),
      ],
    );
  }
}
