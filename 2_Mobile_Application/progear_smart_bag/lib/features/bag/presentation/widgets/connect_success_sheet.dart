// lib/features/bag/presentation/widgets/connect_success_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';
import 'package:progear_smart_bag/shared/widgets/progear_button.dart';

class ConnectSuccessSheet extends StatelessWidget {
  final VoidCallback? onSetWeight;

  const ConnectSuccessSheet({
    super.key,
    this.onSetWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: AppSizes.xxl),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Container(
              height: 140,
              width: 140,
              margin: const EdgeInsets.only(bottom: AppSizes.lg),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.bleGreenInner41.withValues(alpha: 0.35),
                    blurRadius: 32,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 70,
                  color: AppColors.bleGreenInner41,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            const Text(
              "You’re all set!",
              textAlign: TextAlign.center,
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              "Your ProGear bag is now connected.\n"
              "Let’s save your usual bag weight so we can track any changes.",
              textAlign: TextAlign.center,
              style: AppTextStyles.secondary,
            ),
            const SizedBox(height: AppSizes.xxl),
            Row(
              children: [
                Expanded(
                  child: ProGearButton.outlined(
                    label: 'Later',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context, false);
                    },
                    size: ProGearButtonSize.lg,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: ProGearButton.primary(
                    label: 'Set bag weight now',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context, true);
                      if (onSetWeight != null) {
                        onSetWeight!();
                      }
                    },
                    size: ProGearButtonSize.lg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }
}
