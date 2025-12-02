import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';

enum BagStatus {
  missing,
  ok,
  extra,
}

class MissingAlertCard extends StatelessWidget {
  final BagStatus status;

  const MissingAlertCard({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    // ---------- choose text only ----------
    late final String title;

    switch (status) {
      case BagStatus.missing:
        title = "Looks like\nsomething’s\nmissing!";
        break;

      case BagStatus.ok:
        title = "All good!";
        break;

      case BagStatus.extra:
        title = "Carrying more\nthan usual?";
        break;
    }

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
