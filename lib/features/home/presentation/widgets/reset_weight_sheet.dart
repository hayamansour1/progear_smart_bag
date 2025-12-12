// lib/features/home/presentation/widgets/reset_weight_sheet.dart
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

import 'package:progear_smart_bag/features/activity/data/activity_seen_store.dart';

class ResetWeightSheet extends StatefulWidget {
  final String controllerID;

  const ResetWeightSheet({super.key, required this.controllerID});

  @override
  State<ResetWeightSheet> createState() => _ResetWeightSheetState();
}

class _ResetWeightSheetState extends State<ResetWeightSheet> {
  final _sb = Supabase.instance.client;

  bool _loading = false;

  double? _currentG;
  DateTime? _updatedAt;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    try {
      final row = await _sb
          .from('esp32_controller')
          .select('currentWeight, inserted_at')
          .eq('controllerID', widget.controllerID)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _currentG = (row?['currentWeight'] as num?)?.toDouble();
        final ts = row?['inserted_at'] as String?;
        _updatedAt = ts != null ? DateTime.tryParse(ts) : null;
      });
    } catch (_) {
    }
  }

  String _fmtTime(DateTime t) {
    final l = t.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  /// Use live weight from WeightController, update expectedWeight in DB,
  /// log a notification, update local controller + unread activity.
  Future<void> _confirmReset() async {
    setState(() => _loading = true);
    try {
      final weightCtrl = context.read<WeightController>();
      final currentG = weightCtrl.currentG;

      await _sb.rpc('set_expected_weight', params: {
        'p_controller': widget.controllerID,
        'p_value': currentG,
      });

      final uid = _sb.auth.currentUser?.id;
      if (uid != null) {
        await _sb.rpc('insert_notification', params: {
          'p_controller': widget.controllerID,
          'p_user': uid,
          'p_kind': 'weight_reset',
          'p_title': 'Expected updated',
          'p_message':
              'Expected weight set to ${currentG.toStringAsFixed(1)} g.',
          'p_severity': 'success',
          'p_meta': {
            'current_g': currentG,
          },
        });
      }

      weightCtrl.applyExpectedFromReset(currentG);

      try {
        await ActivitySeenStore.instance.bumpUnread(widget.controllerID);
      } catch (_) {
      }

      await _loadSnapshot();

      await HapticFeedback.lightImpact();
      ProGearToast.show(
        'Expected weight updated to ${currentG.toStringAsFixed(1)} g.',
      );

      if (!mounted) return;
      Navigator.pop(context, true); // close with success
    } catch (e) {
      if (!mounted) return;
      ProGearToast.show('Reset failed: $e', style: ToastStyle.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentHint = _currentG == null
        ? null
        : '${_currentG!.toStringAsFixed(1)} g'
            '${_updatedAt == null ? '' : ' • ${_fmtTime(_updatedAt!)}'}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final bool short = maxH < 560;

        final illusSize = (maxH * 0.22).clamp(140.0, 150.0).toDouble();
        final illusImg = illusSize * 0.82;
        final handleGap = (AppSizes.xl).clamp(16.0, 26.0);

        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: EdgeInsets.only(bottom: handleGap),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // ─ Illustration 
            Container(
              height: illusSize,
              width: illusSize,
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
              "We’ll update your bag’s weight",
              textAlign: TextAlign.center,
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: AppSizes.sm),

            // ─ Description
            Text(
              "Just pack your stuff as usual and place the bag on a stable surface. "
              "Avoid moving it for best accuracy.",
              textAlign: TextAlign.center,
              style: AppTextStyles.secondary.copyWith(
                fontSize: AppSizes.fontSm,
                height: 1.4,
              ),
            ),

            // ─ Small hint with current snapshot
            if (currentHint != null) ...[
              const SizedBox(height: AppSizes.md),
              Text(
                'Current • $currentHint',
                textAlign: TextAlign.center,
                style: AppTextStyles.secondary.copyWith(
                  color: Colors.white70,
                  fontSize: AppSizes.fontSm,
                ),
              ),
            ],

            const SizedBox(height: AppSizes.lg),

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
                    label: _loading ? 'Working…' : 'Done',
                    onPressed: _loading
                        ? null
                        : () async {
                            await HapticFeedback.selectionClick();
                            await _confirmReset();
                          },
                    size: ProGearButtonSize.lg,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.lg),
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
