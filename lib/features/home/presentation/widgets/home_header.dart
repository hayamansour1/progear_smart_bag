import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white10,
          child: Text('H', style: AppTextStyles.heading2),
        ),
        const SizedBox(width: AppSizes.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hey, Haya', style: AppTextStyles.heading2),
              const SizedBox(height: 2),
              Text('Ready to go?', style: AppTextStyles.secondary),
            ],
          ),
        ),

        const _HeaderIcon(Icons.notifications_outlined, badge: true),
        const SizedBox(width: 8),
        const _HeaderIcon(Icons.settings_outlined),
        const SizedBox(width: 8),
        _HeaderIcon(
          Icons.logout,
          onTap: () async => Supabase.instance.client.auth.signOut(),
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final bool badge;
  final VoidCallback? onTap;
  const _HeaderIcon(this.icon, {this.badge = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 22, color: Colors.white),
          if (badge)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
    return GestureDetector(onTap: onTap, child: child);
  }
}
