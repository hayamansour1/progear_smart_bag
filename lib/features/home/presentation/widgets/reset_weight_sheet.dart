import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';
import 'package:progear_smart_bag/shared/widgets/progear_button.dart';
import 'package:progear_smart_bag/core/constants/app_images.dart';

// Local unread store (header dot / badges)
import 'package:progear_smart_bag/features/activity/data/activity_seen_store.dart';

// Update WeightController locally after reset
import 'package:progear_smart_bag/features/weight/logic/weight_controller.dart';

// Floating toast (uses rootMessengerKey)
import 'package:progear_smart_bag/shared/widgets/progear_toast.dart';

class ResetWeightSheet extends StatefulWidget {
  /// NOTE: when BLE is ready, pass the real connected controller id from Bluetooth layer:
  /// final controllerID = context.read`<BluetoothController>`().connectedDevice?.remoteId.str;
  /// For now we pass a fixed testing id from the caller (HomeDashboardPage).
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

  /// Lightweight snapshot for the tiny "Current • ..." hint.
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
    } catch (_) {}
  }

  /// Calls RPC to set expectedWeight = currentWeight, logs a notification,
  Future<void> _confirmReset() async {
    setState(() => _loading = true);
    try {
      // 1) Update expected := current in DB
      await _sb.rpc('reset_expected_to_current', params: {
        'p_controller': widget.controllerID,
      });

      // 2) Log an in-app notification
      final uid = _sb.auth.currentUser?.id;
      if (uid != null) {
        await _sb.rpc('insert_notification', params: {
          'p_controller': widget.controllerID,
          'p_user': uid,
          'p_kind': 'weight_reset',
          'p_title': 'Expected updated',
          'p_message': 'Expected weight set to current successfully.',
          'p_severity': 'success',
          'p_meta': {
            'current_g': _currentG,
          },
        });
      }

      // 3) Update WeightController locally so UI reflects the new expected instantly
      try {
        final w = _currentG ?? 0;
        if (!w.isNaN) {
          // ignore: use_build_context_synchronously
          context.read<WeightController>().applyExpectedFromReset(w);
        }
      } catch (_) {
        // Non-fatal
      }

      // 4) Mark unread locally so the header dot shows immediately
      try {
        await ActivitySeenStore.instance.bumpUnread(widget.controllerID);
      } catch (_) {
        // Non-fatal
      }

      // 5) Haptics + toast feedback, then close the sheet
      await HapticFeedback.lightImpact();
      ProGearToast.show('Expected weight updated to current.');

      if (!mounted) return;
      Navigator.pop(context, true); // close with success
    } catch (e) {
      if (!mounted) return;
      ProGearToast.show('Reset failed: $e', style: ToastStyle.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtTime(DateTime t) {
    final l = t.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentHint = _currentG == null
        ? null
        : '${_currentG!.toStringAsFixed(1)} g'
            '${_updatedAt == null ? '' : ' • ${_fmtTime(_updatedAt!)}'}';

    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;

        // Responsive illustration sizing (safe for short heights)
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

            // ─ Illustration (PNG inside a soft glowing circle)
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
                fontSize: AppSizes.fontMd,
              ),
            ),

            // ─ hint
            if (currentHint != null) ...[
              SizedBox(height: blockGap),
              Text(
                'Current • $currentHint',
                textAlign: TextAlign.center,
                style: AppTextStyles.secondary.copyWith(
                  color: Colors.white70,
                  fontSize: AppSizes.fontSm,
                ),
              ),
            ],

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
                    label: _loading ? 'Working…' : 'Done',
                    onPressed: _loading
                        ? null
                        : () async {
                            // Immediate tap haptic
                            await HapticFeedback.selectionClick();
                            await _confirmReset();
                          },
                    size: ProGearButtonSize.lg,
                  ),
                ),
              ],
            ),

            // Extra bottom gap so buttons don't stick to the edge
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
                // keep a little headroom so content never overflows
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
