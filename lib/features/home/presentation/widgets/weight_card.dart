import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';

class WeightCard extends StatelessWidget {
  final double currentKg;
  final double maxKg;
  const WeightCard({super.key, required this.currentKg, required this.maxKg});

  @override
  Widget build(BuildContext context) {
    final ratio = (currentKg / maxKg).clamp(0.0, 1.0);

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
          Row(
            children: [
              Text('${currentKg.toStringAsFixed(1)}',
                  style: AppTextStyles.heading2),
              const SizedBox(width: 4),
              Text('KG', style: AppTextStyles.secondary),
              const Spacer(),
              Text('${maxKg.toStringAsFixed(0)}',
                  style: AppTextStyles.heading2),
              const SizedBox(width: 4),
              Text('KG', style: AppTextStyles.secondary),
            ],
          ),
          const SizedBox(height: AppSizes.md),
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
}
