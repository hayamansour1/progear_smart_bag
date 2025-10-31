import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';

// When BLE is ready, read controllerID from BluetoothController.
// For now, we keep a TEMP fallback id.
// We also read/write a local unread flag via ActivitySeenStore.
import 'package:progear_smart_bag/features/activity/data/activity_seen_store.dart';
// import 'package:provider/provider.dart';
// import 'package:progear_smart_bag/features/bag/controllers/bluetooth_controller.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  // FIX: initialize with empty string to avoid LateInitializationError during first build
  String _controllerID = '';
  bool _unread = false; 

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<String> _resolveControllerID(BuildContext context) async {
    // REAL line (when BLE is ready):
    // final id = context.read<BluetoothController>().connectedDevice?.remoteId.str;
    // if (id != null && id.isNotEmpty) return id;

    // TEMP fallback for testing:
    return 'ctrl_14be0569';
  }

  Future<void> _init() async {
    final id = await _resolveControllerID(context);
    final unread = await ActivitySeenStore.instance.hasUnread(id);
    if (!mounted) return;
    setState(() {
      _controllerID = id;
      _unread = unread;
    });
  }

  Future<void> _openActivity() async {
    setState(() => _unread = false);

    // Navigate to unified Activity (passes controller id in the query)
    await context.push('/activity?cid=$_controllerID');

    // After returning, re-check unread flag (ActivityPage clears it on load)
    final stillUnread =
        await ActivitySeenStore.instance.hasUnread(_controllerID);
    if (!mounted) return;
    setState(() => _unread = stillUnread);
  }

  @override
  Widget build(BuildContext context) {
    // While initializing, render a small placeholder to keep layout stable
    if (_controllerID.isEmpty) {
      return const SizedBox(height: 56);
    }

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

        // Notifications --> Unified Activity Page
        _HeaderIcon(
          icon: Icons.notifications_outlined,
          showDot: _unread, 
          onTap: _openActivity,
        ),
        const SizedBox(width: 8),

        // TODO: Settings (stub)
        const _HeaderIcon(icon: Icons.settings_outlined),

        const SizedBox(width: 8),

        // Sign out
        _HeaderIcon(
          icon: Icons.logout,
          onTap: () async => Supabase.instance.client.auth.signOut(),
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  final VoidCallback? onTap;

  const _HeaderIcon({
    required this.icon,
    this.showDot = false,
    this.onTap,
  });

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
          if (showDot)
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
