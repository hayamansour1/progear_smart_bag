// lib/features/bag/presentation/widgets/connect_bag_sheet.dart
import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';
import 'package:progear_smart_bag/core/constants/app_images.dart';
import 'package:progear_smart_bag/shared/widgets/progear_button.dart';

import 'package:progear_smart_bag/features/bag/presentation/widgets/show_bluetooth_devices.dart';

class ConnectBagSheet extends StatelessWidget {
  const ConnectBagSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(22),
        ),
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
            // grab handle
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: AppSizes.lg),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // illustration
            Container(
              height: isPortrait ? 120 : 120,
              width: isPortrait ? 120 : 120,
              margin: const EdgeInsets.only(bottom: AppSizes.lg),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.22),
                    blurRadius: 30,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  AppImages.logoBag,
                  width: isPortrait ? 90 : 90,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const Text(
              "Let’s get your bag connected",
              textAlign: TextAlign.center,
              style: AppTextStyles.heading1,
            ),

            const SizedBox(height: AppSizes.md),

            Align(
              alignment: Alignment.center,
              child: Container(
                width: 280,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Just follow these steps:",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.secondary,
                    ),
                    SizedBox(height: AppSizes.sm),
                    Text(
                      "1. Turn on your smart bag",
                      style: AppTextStyles.bodySM,
                    ),
                    SizedBox(height: AppSizes.xs),
                    Text(
                      "2. Tap “Connect Now” to open Bluetooth Settings",
                      style: AppTextStyles.bodySM,
                    ),
                    SizedBox(height: AppSizes.xs),
                    Text(
                      "3. Select “ProGear Bag”",
                      style: AppTextStyles.bodySM,
                    ),
                    SizedBox(height: AppSizes.xs),
                    Text(
                      "4. Come back here once you're connected",
                      style: AppTextStyles.bodySM,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            Row(
              children: [
                Expanded(
                  child: ProGearButton.outlined(
                    label: 'Not now',
                    onPressed: () => Navigator.pop(context, false),
                    size: ProGearButtonSize.lg,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: ProGearButton.primary(
                    label: 'Connect now',
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        useSafeArea: true,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ShowBluetoothDevices(
                          parentContext: context,
                        ),
                      );
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
