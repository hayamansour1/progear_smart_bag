import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';

/// WeightCard
/// Displays the current and expected bag weight (in grams).
/// Currently uses dummy values until BLE/DB is fully integrated.
class WeightCard extends StatelessWidget {
  final double currentG;   // current bag weight (grams)
  final double expectedG;  // expected reference weight (grams)

  const WeightCard({
    super.key,
    required this.currentG,
    required this.expectedG,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (currentG / expectedG).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bag Weight', style: AppTextStyles.heading1),
          const SizedBox(height: AppSizes.md),

          // Values (left = current, right = expected)
          Row(
            children: [
              Text(currentG.toStringAsFixed(1),
                  style: AppTextStyles.heading2),
              const SizedBox(width: 4),
              Text('g', style: AppTextStyles.secondary),
              const Spacer(),
              Text(expectedG.toStringAsFixed(1),
                  style: AppTextStyles.heading2),
              const SizedBox(width: 4),
              Text('g', style: AppTextStyles.secondary),
            ],
          ),

          const SizedBox(height: AppSizes.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 16,
              backgroundColor: Colors.white.withValues(alpha: .08),
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  // Example placeholder for future data binding.
  //// ------------------------------------------------
  // // TODO: When BLE is ready, replace constructor with:
  // WeightCard(
  //   currentG: context.watch<BluetoothController>().currentWeightG,
  //   expectedG: context.watch<BluetoothController>().expectedWeightG,
  // )
  //
  // // TEMP fallback for testing (replace when ready):
  // const WeightCard(currentG: 5600, expectedG: 8000);
  //// ------------------------------------------------
}
