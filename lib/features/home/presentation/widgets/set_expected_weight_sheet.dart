// lib/features/home/presentation/widgets/set_expected_weight_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';
import 'package:progear_smart_bag/core/constants/app_images.dart';
import 'package:progear_smart_bag/shared/widgets/progear_button.dart';

// Local unread store (header dot / badges)
import 'package:progear_smart_bag/features/activity/data/activity_seen_store.dart';

// WeightController: نقرأ منه الوزن الحالي + نحدّث expected محلياً
import 'package:progear_smart_bag/features/weight/logic/weight_controller.dart';

// Floating toast (uses rootMessengerKey)
import 'package:progear_smart_bag/shared/widgets/progear_toast.dart';

/// SetExpectedWeightSheet:
/// أول مرة يضبط فيها اليوزر الوزن المتوقع للحقيبة.
/// الفكرة: اليوزر يحط كل أغراضه المعتادة → يثبت الشنطة → يضغط Done.
/// حنا ناخذ currentG من WeightController ونحفظه كـ expectedWeight في DB.
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
  final _sb = Supabase.instance.client;
  bool _loading = false;

  Future<void> _confirmSet() async {
    setState(() => _loading = true);
    try {
      // 1) نجيب الوزن الحالي من WeightController (live من BLE)
      final weightCtrl = context.read<WeightController>();
      final currentG = weightCtrl.currentG;

      // 2) نحدّث expectedWeight = currentG في الـ DB
      await _sb.rpc('set_expected_weight', params: {
        'p_controller': widget.controllerID,
        'p_value': currentG,
      });

      // 3) نسجّل Notification كبداية لاستخدام الشنطة
      final uid = _sb.auth.currentUser?.id;
      if (uid != null) {
        await _sb.rpc('insert_notification', params: {
          'p_controller': widget.controllerID,
          'p_user': uid,
          'p_kind': 'expected_init',
          'p_title': 'Baseline weight set',
          'p_message':
              'We saved your usual bag weight as ${currentG.toStringAsFixed(1)} g.',
          'p_severity': 'success',
          'p_meta': {
            'current_g': currentG,
          },
        });

        // نعلّم ActivitySeenStore إن فيه حدث جديد
        await ActivitySeenStore.instance.bumpUnread(widget.controllerID);
      }

      // 4) نحدّث الكنترولر محلياً عشان الـ UI يتحدّث مباشرة
      weightCtrl.applyExpectedFromReset(currentG);

      // 5) Haptics + Toast + إغلاق
      await HapticFeedback.lightImpact();
      ProGearToast.show(
        'Baseline saved: ${currentG.toStringAsFixed(1)} g.',
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ProGearToast.show(
        'Could not set weight: $e',
        style: ToastStyle.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;

        final illusSize = (maxH * 0.28).clamp(140.0, 200.0).toDouble();
        final illusImg = (illusSize * 0.88).toDouble();

        final topHandleBottom = (AppSizes.xxl).clamp(16.0, 28.0);
        final belowIllustration = (AppSizes.lg).clamp(12.0, 24.0);
        final blockGap = (AppSizes.xxl).clamp(16.0, 28.0);
        final bottomSafeGap = isPortrait ? AppSizes.lg : AppSizes.sm;

        final needsScroll = maxH < 560;

        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─ Grab handle
            Container(
              width: 44,
              height: 5,
              margin: EdgeInsets.only(bottom: topHandleBottom),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // ─ Illustration (بانر الوزن)
            Container(
              height: illusSize,
              width: illusSize,
              margin: EdgeInsets.only(bottom: belowIllustration),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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

            // ─ Description
            Text(
              "Pack everything you usually carry in your bag, then place it on a stable surface. "
              "We’ll save this as your baseline weight so we can alert you when something changes.",
              textAlign: TextAlign.center,
              style: AppTextStyles.secondary.copyWith(
                fontSize: AppSizes.fontMd,
              ),
            ),

            SizedBox(height: blockGap),

            // ─ Actions
            Row(
              children: [
                Expanded(
                  child: ProGearButton.outlined(
                    label: 'Cancel',
                    onPressed:
                        _loading ? null : () => Navigator.pop(context, false),
                    size: ProGearButtonSize.lg,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: ProGearButton.primary(
                    label: _loading ? 'Saving…' : 'Done',
                    onPressed: _loading
                        ? null
                        : () async {
                            await HapticFeedback.selectionClick();
                            await _confirmSet();
                          },
                    size: ProGearButtonSize.lg,
                  ),
                ),
              ],
            ),

            SizedBox(height: bottomSafeGap),
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
              constraints: BoxConstraints(
                maxHeight: maxH * 0.92,
              ),
              child: needsScroll
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
