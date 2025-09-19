import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';

class BagStatusCard extends StatelessWidget {
  final bool connected;
  const BagStatusCard({super.key, required this.connected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.xl,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 8,
                  top: 8,
                  child: Icon(
                    Icons.bluetooth_connected,
                    color: connected ? Colors.blueAccent : Colors.white30,
                    size: 28,
                  ),
                ),
                Image.asset(
                  'assets/bag_logo.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            connected ? 'Connected' : 'Disconnected',
            style: AppTextStyles.heading2.copyWith(
              shadows: [
                if (connected)
                  Shadow(
                      color: Colors.greenAccent.withValues(alpha: .2),
                      blurRadius: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
