// lib/features/home/presentation/widgets/battery_card.dart
import 'package:flutter/material.dart';
import 'package:cupertino_battery_indicator/cupertino_battery_indicator.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';

class BatteryCard extends StatelessWidget {
  final int percent; // 0..100
  final bool isCharging;
  final DateTime? lastUpdated;

  const BatteryCard({
    super.key,
    required this.percent,
    this.isCharging = false,
    this.lastUpdated,
  });

  static const _iosGreen = Color(0xFF34C759);
  static const _iosYellow = Color(0xFFFFCC00);
  static const _iosRed = Color(0xFFFF3B30);

  Color _iosTint(double level, bool charging) {
    if (!charging) return Colors.white;
    if (level <= .20) return _iosRed;
    if (level <= .50) return _iosYellow;
    return _iosGreen;
  }

  // --------- (Optional) format time function IF NEDED ----------
  /*
  String _fmtTime(DateTime t) {
    final l = t.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')} • '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
  */

  @override
  Widget build(BuildContext context) {
    final p = percent.clamp(0, 100);
    final level = p / 100.0;
    final tint = _iosTint(level, isCharging);

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.mode(tint, BlendMode.srcATop),
                  child: BatteryIndicator(
                    value: level,
                    trackHeight: 42,
                  ),
                ),
                if (isCharging)
                  const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$p%',
            style: AppTextStyles.heading.copyWith(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),

          /*
          if (lastUpdated != null) ...[
            const SizedBox(height: 6),
            Text(
              'Last update • ${_fmtTime(lastUpdated!)}',
              style: AppTextStyles.secondary.copyWith(
                fontSize: AppSizes.fontSm,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          */
        ],
      ),
    );
  }
}
