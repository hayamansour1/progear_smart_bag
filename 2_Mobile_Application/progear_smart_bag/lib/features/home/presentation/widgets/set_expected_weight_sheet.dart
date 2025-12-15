import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';
import 'package:progear_smart_bag/core/constants/app_images.dart';

import 'package:progear_smart_bag/shared/widgets/progear_button.dart';
import 'package:progear_smart_bag/features/weight/logic/weight_controller.dart';
import 'package:progear_smart_bag/shared/widgets/progear_toast.dart';

class SetExpectedWeightSheet extends StatefulWidget {
  final String controllerID;

  const SetExpectedWeightSheet({
    super.key,
    required this.controllerID,
  });

  @override
  State<SetExpectedWeightSheet> createState() => _SetExpectedWeightSheetState();
}

class _SetExpectedWeightSheetState extends State<SetExpectedWeightSheet> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    await HapticFeedback.selectionClick();

    try {
      final sb = Supabase.instance.client;
      final weightCtrl = context.read<WeightController>();
      final current = weightCtrl.currentG;

      // RPC
      await sb.rpc('reset_expected_to_current', params: {
        'p_controller': widget.controllerID,
      });

      // Update local baseline
      weightCtrl.applyExpectedFromReset(current);

      if (!mounted) return;
      Navigator.pop(context, true);

      ProGearToast.show(
        'Bag weight saved as your default.',
        style: ToastStyle.success,
      );
    } catch (e) {
      if (!mounted) return;

      ProGearToast.show(
        'Failed to save weight. Please try again.',
        style: ToastStyle.error,
      );

      setState(() => _saving = false);
    }
  }

  // bullet widget
  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "•  ",
            style: TextStyle(
              color: Colors.white70,
              fontSize: AppSizes.fontSm,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.secondary.copyWith(
                fontSize: AppSizes.fontSm,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final bool short = maxH < 560;

        // illustration sizing
        final illusSize = (maxH * 0.22).clamp(100.0, 150.0).toDouble();
        final illusImg = illusSize * 0.82;

        final handleGap = (AppSizes.xl).clamp(16.0, 26.0);

        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─ Grab handle
            Container(
              width: 44,
              height: 5,
              margin: EdgeInsets.only(bottom: handleGap),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // ─ Illustration (circle with PNG)
            Container(
              height: illusSize,
              width: illusSize,
              margin: const EdgeInsets.only(bottom: AppSizes.lg),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.22),
                    blurRadius: 26,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  AppImages.resetWeight,
                  width: illusImg,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // ─ Title
            const Text(
              "Let’s set your bag’s weight",
              textAlign: TextAlign.center,
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: AppSizes.sm),

            // ─ Bullet list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bullet("Pack everything you usually carry in your bag."),
                  _bullet("Place the bag on a stable, flat surface."),
                  _bullet("Keep the bag still for a few seconds."),
                  _bullet("Tap “Save weight” to set this as your default."),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.xxl),

            // ─ Buttons
            Row(
              children: [
                Expanded(
                  child: ProGearButton.outlined(
                    label: 'Not now',
                    onPressed: () async {
                      await HapticFeedback.selectionClick();
                      if (!mounted) return;
                      Navigator.pop(context, false);
                    },
                    size: ProGearButtonSize.lg,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: ProGearButton.primary(
                    label: _saving ? 'Saving…' : 'Save weight',
                    onPressed: _saving ? null : _save,
                    size: ProGearButtonSize.lg,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSizes.lg),
          ],
        );

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
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: maxH * (short ? 0.96 : 0.9)),
              child: short
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: content,
                    )
                  : content,
            ),
          ),
        );
      },
    );
  }
}
