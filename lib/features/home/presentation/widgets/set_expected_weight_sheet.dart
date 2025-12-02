// lib/features/home/presentation/widgets/set_expected_weight_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';
import 'package:progear_smart_bag/shared/widgets/progear_button.dart';
import 'package:progear_smart_bag/features/weight/logic/weight_controller.dart';

/// شيت لتثبيت الوزن الحالي كـ expectedWeight في قاعدة البيانات.
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
  String? _error;

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    await HapticFeedback.selectionClick();

    try {
      final sb = Supabase.instance.client;

      // نجيب الكنترولر و الوزن الحالي قبل ما نسوي الـ RPC
      final weightCtrl = context.read<WeightController>();
      final current = weightCtrl.currentG;

      await sb.rpc('reset_expected_to_current', params: {
        'p_controller': widget.controllerID,
      });

      // نحدّث الـ baseline محلياً عشان الـ UI ينقز مباشرة
      weightCtrl.applyExpectedFromReset(current);

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          content: Text('Bag weight saved as your default weight.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to save weight. Please try again.';
        _saving = false;
      });
    }
  }

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
            // grab handle
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: AppSizes.xl),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            const Text(
              'Save your usual bag weight',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: AppSizes.sm),
            const Text(
              'We’ll use the current bag reading as your default weight.\n'
              'Later, you can reset it anytime from the dashboard.',
              textAlign: TextAlign.center,
              style: AppTextStyles.secondary,
            ),
            const SizedBox(height: AppSizes.xxl),

            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.md),
            ],

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

            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }
}
