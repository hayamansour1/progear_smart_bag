import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';

class MissingAlertCard extends StatelessWidget {
  const MissingAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          "Looks like\n something’s\n missing!",
          style: AppTextStyles.heading2,
        ),
      ),
    );
  }
}
