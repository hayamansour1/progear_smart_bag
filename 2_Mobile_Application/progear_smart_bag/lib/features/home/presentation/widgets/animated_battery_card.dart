import 'package:flutter/material.dart';
import 'package:cupertino_battery_indicator/cupertino_battery_indicator.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';

class AnimatedBatteryCard extends StatefulWidget {
  final int percent; // 0..100
  final bool isCharging;
  final DateTime? lastUpdated;
  final Duration tweenDuration;

  const AnimatedBatteryCard({
    super.key,
    required this.percent,
    this.isCharging = false,
    this.lastUpdated,
    this.tweenDuration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedBatteryCard> createState() => _AnimatedBatteryCardState();
}

class _AnimatedBatteryCardState extends State<AnimatedBatteryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  double _prev = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isCharging) _pulseCtrl.repeat(reverse: true);
    _prev = (widget.percent.clamp(0, 100)) / 100.0;
  }

  @override
  void didUpdateWidget(covariant AnimatedBatteryCard old) {
    super.didUpdateWidget(old);
    if (widget.isCharging != old.isCharging) {
      if (widget.isCharging) {
        _pulseCtrl.repeat(reverse: true);
      } else {
        _pulseCtrl.stop();
        _pulseCtrl.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color _lerpLevelColor(double t) {
    if (t <= .20) return AppColors.bleRedInner49;
    if (t <= .50) {
      final localT = (t - .20) / .30;
      return Color.lerp(AppColors.bleRedInner49, Colors.amberAccent, localT)!;
    }
    final localT = (t - .50) / .50;
    return Color.lerp(Colors.amberAccent, AppColors.bleGreenInner41, localT)!;
  }

  String _fmtTime(DateTime t) {
    final l = t.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')} • '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final next = (widget.percent.clamp(0, 100)) / 100.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _prev, end: next),
      duration: widget.tweenDuration,
      curve: Curves.easeOutCubic,
      onEnd: () => _prev = next,
      builder: (context, value, _) {
        final pct = (value * 100).round();
        final color = _lerpLevelColor(value);

        return Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.white.withValues(alpha: .08), width: 1),
          ),
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Battery', style: AppTextStyles.heading2),
                  const Spacer(),
                  if (widget.isCharging)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: .4),
                          width: .8,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Charging', style: AppTextStyles.secondary),
                        ],
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      final pulse = widget.isCharging ? _pulseCtrl.value : 0.0;
                      return Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            if (widget.isCharging)
                              BoxShadow(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.25 + 0.25 * pulse),
                                blurRadius: 12 + 8 * pulse,
                                spreadRadius: 1 + 2 * pulse,
                              ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: BatteryIndicator(
                      value: value, // 0..1
                      icon: widget.isCharging
                          ? const Icon(Icons.bolt, color: Colors.white)
                          : null,
                      iconOutline: Colors.white,
                      iconOutlineBlur: 1.0,
                      trackHeight: 22,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Text(
                    '$pct%',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 36,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              if (widget.lastUpdated != null)
                Text(
                  'Last update: ${_fmtTime(widget.lastUpdated!)}',
                  style: AppTextStyles.secondary
                      .copyWith(fontSize: AppSizes.fontMd),
                ),
            ],
          ),
        );
      },
    );
  }
}
