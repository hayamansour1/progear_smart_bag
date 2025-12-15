// lib/features/home/presentation/widgets/home_header.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';

import 'package:progear_smart_bag/features/bag/controllers/bluetooth_controller.dart';
import 'package:progear_smart_bag/features/activity/data/activity_seen_store.dart';
import 'package:progear_smart_bag/features/activity/data/last_controller_store.dart';
import 'package:progear_smart_bag/features/weight/logic/weight_bridge.dart';
import 'package:progear_smart_bag/features/home/logic/battery_bridge.dart';
import 'package:progear_smart_bag/features/weight/logic/weight_controller.dart';
import 'package:progear_smart_bag/features/home/logic/battery_controller.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String? _controllerID;
  bool _unread = false;

  BluetoothController? _btCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _btCtrl = context.read<BluetoothController>();
      _btCtrl?.addListener(_onBluetoothChanged);
      _loadInitialControllerID();
    });
  }

  Future<void> _loadInitialControllerID() async {
    final ctrl = _btCtrl;
    if (ctrl == null) return;

    final liveId = ctrl.connectedDevice?.remoteId.str;
    if (liveId != null && liveId.isNotEmpty) {
      final unread = await ActivitySeenStore.instance.hasUnread(liveId);
      if (!mounted) return;
      setState(() {
        _controllerID = liveId;
        _unread = unread;
      });
      return;
    }

    final lastId = await LastControllerStore.instance.getLastControllerID();
    if (lastId != null && lastId.isNotEmpty) {
      final unread = await ActivitySeenStore.instance.hasUnread(lastId);
      if (!mounted) return;
      setState(() {
        _controllerID = lastId;
        _unread = unread;
      });
      return;
    }

    final sb = Supabase.instance.client;
    final user = sb.auth.currentUser;
    if (user == null) return;

    try {
      final row = await sb
          .from('esp32_controller')
          .select('controllerID')
          .eq('userID', user.id)
          .limit(1)
          .maybeSingle();

      final dbId = row == null ? null : row['controllerID'] as String?;
      if (dbId == null || dbId.isEmpty) return;

      final unread = await ActivitySeenStore.instance.hasUnread(dbId);
      if (!mounted) return;
      setState(() {
        _controllerID = dbId;
        _unread = unread;
      });

      await LastControllerStore.instance.setLastControllerID(dbId);
    } catch (e) {
      debugPrint('HomeHeader _loadInitialControllerID DB error: $e');
    }
  }

  void _onBluetoothChanged() async {
    final ctrl = _btCtrl;
    if (ctrl == null) return;

    final liveId = ctrl.connectedDevice?.remoteId.str;

    if ((liveId == null || liveId.isEmpty) && _controllerID != null) {
      return;
    }

    if (liveId == null || liveId.isEmpty) {
      if (_controllerID != null) {
        setState(() {
          _controllerID = null;
          _unread = false;
        });
      }
      return;
    }

    if (liveId != _controllerID) {
      await LastControllerStore.instance.setLastControllerID(liveId);
      final unread = await ActivitySeenStore.instance.hasUnread(liveId);
      if (!mounted) return;
      setState(() {
        _controllerID = liveId;
        _unread = unread;
      });
    }
  }

  Future<void> _openActivity() async {
    final cid = _controllerID;

    setState(() => _unread = false);

    if (cid != null && cid.isNotEmpty) {
      await context.push('/activity?cid=$cid');
    } else {
      await context.push('/activity');
    }

    if (cid != null && cid.isNotEmpty) {
      final stillUnread = await ActivitySeenStore.instance.hasUnread(cid);
      if (!mounted) return;
      setState(() => _unread = stillUnread);
    }
  }

  Future<void> _handleLogout() async {
    try {
      final bt = context.read<BluetoothController>();
      final weightCtrl = context.read<WeightController>();
      final batteryCtrl = context.read<BatteryController>();

      if (bt.connectedDevice != null) {
        await bt.disconnectDevice(bt.connectedDevice!);
      }

      await WeightBridge.unbind(weightCtrl);
      await BatteryBridge.unbind(batteryCtrl);

      weightCtrl.resetForNewOwner();
      batteryCtrl.resetState();

      await LastControllerStore.instance.clear();
    } catch (e) {
      debugPrint('Logout BLE cleanup error: $e');
    }

    try {
      if (!mounted) return;
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut error: $e');
    }
  }

  @override
  void dispose() {
    _btCtrl?.removeListener(_onBluetoothChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<BluetoothController>();

    final user = Supabase.instance.client.auth.currentUser;
    final storedName = (user?.userMetadata?['name'] as String?)?.trim();

    final displayName = (storedName == null || storedName.isEmpty)
        ? 'ProGear user'
        : storedName;

    final avatarLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white10,
          child: Text(avatarLetter, style: AppTextStyles.heading2),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hey, $displayName', style: AppTextStyles.heading2),
              const SizedBox(height: 2),
              const Text('Ready to go?', style: AppTextStyles.secondary),
            ],
          ),
        ),
        _HeaderIcon(
          icon: Icons.notifications_outlined,
          showDot: _unread,
          onTap: _openActivity,
        ),
        const SizedBox(width: 8),
        _HeaderIcon(
          icon: Icons.settings_outlined,
          onTap: () => context.push('/settings'),
        ),
        const SizedBox(width: 8),
        _HeaderIcon(
          icon: Icons.logout,
          onTap: _handleLogout,
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

    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }
}
