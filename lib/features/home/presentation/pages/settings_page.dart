// lib/features/home/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:progear_smart_bag/core/constants/app_colors.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';

import 'package:progear_smart_bag/features/bag/controllers/bluetooth_controller.dart';
import 'package:progear_smart_bag/features/activity/data/last_controller_store.dart';
import 'package:progear_smart_bag/features/weight/logic/weight_bridge.dart';
import 'package:progear_smart_bag/features/home/logic/battery_bridge.dart';
import 'package:progear_smart_bag/features/weight/logic/weight_controller.dart';
import 'package:progear_smart_bag/features/home/logic/battery_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _removeCurrentBag(BuildContext context) async {
    final bt = context.read<BluetoothController>();
    final weightCtrl = context.read<WeightController>();
    final batteryCtrl = context.read<BatteryController>();
    final sb = Supabase.instance.client;

    // نحدد الـ controllerID: المتصل حاليًا أو آخر واحد مخزَّن
    final liveId = bt.connectedDevice?.remoteId.str;
    final lastId = await LastControllerStore.instance.getLastControllerID();
    final cid = (liveId != null && liveId.isNotEmpty) ? liveId : lastId;

    if (cid == null || cid.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No bag is currently linked to your account.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundLight,
            title: const Text(
              'Remove Bag',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'This will:\n'
              '• Unpair the bag from your account\n'
              '• Delete its weight & notification history\n\n'
              'After that, another user can pair the bag with their own account.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Remove bag',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      // 1) نطلب من Supabase إزالة الشنطة وكل تاريخها
      await sb.rpc('remove_controller', params: {'p_controller': cid});

      // 2) نفصل الـ BLE لو كان متصل على نفس الشنطة
      if (bt.connectedDevice != null &&
          bt.connectedDevice!.remoteId.str == cid) {
        await bt.disconnectDevice(bt.connectedDevice!);
      }

      // 3) نفصل الـ Streams
      await WeightBridge.unbind(weightCtrl);
      await BatteryBridge.unbind(batteryCtrl);

      // 4) نرجّع الكنترولرز لحالة نظيفة (عشان يوزر جديد ما يشوف بيانات قديمة)
      weightCtrl.resetForNewOwner();
      batteryCtrl.resetState();

      // 5) نفضّي آخر controller مخزَّن
      await LastControllerStore.instance.clear();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bag removed successfully.'),
        ),
      );

      // نرجع لصفحة الهوم
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove bag: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // نخليه شفاف عشان ياخذ نفس الخلفية/الجرادينت من الـ root مثل الهوم
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            Text(
              'Bag Settings',
              style: AppTextStyles.heading2.copyWith(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // حذف الشنطة
            Card(
              color: Colors.white.withValues(alpha: .06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Remove bag from this account',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                subtitle: const Text(
                  'Unpair the bag and delete its weight & notification history.\n'
                  'After that, another user can pair it as a new bag.',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () => _removeCurrentBag(context),
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // Placeholder لإعدادات قادمة
            Text(
              'More settings coming soon…',
              style: AppTextStyles.secondary.copyWith(
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
