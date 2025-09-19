import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';

class BatteryCard extends StatelessWidget {
  final int percent;
  const BatteryCard({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.battery_3_bar, size: 42, color: Colors.white),
          const Spacer(),
          Text('$percent%', style: AppTextStyles.heading.copyWith(fontSize: 44)),
        ],
      ),
    );
  }
}
