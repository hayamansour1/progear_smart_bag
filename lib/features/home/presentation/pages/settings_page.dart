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
import 'package:progear_smart_bag/core/theme/progear_background.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

//Delete Bag Function  
  Future<void> _removeCurrentBag(BuildContext context) async {
    final bt = context.read<BluetoothController>();
    final weightCtrl = context.read<WeightController>();
    final batteryCtrl = context.read<BatteryController>();
    final sb = Supabase.instance.client;

    //
    // 1)  controllerID
    //
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

  
    // 2) Confirmation Dialog
    final confirmed = await showDialog<bool>(
          // ignore: use_build_context_synchronously
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
    if (!context.mounted) return;

    try {

      // 3) Delete Bag from Supabase
      await sb.rpc('remove_controller', params: {'p_controller': cid});


      // 4) Disconnect if connected
      if (bt.connectedDevice != null &&
          bt.connectedDevice!.remoteId.str == cid) {
        await bt.disconnectDevice(bt.connectedDevice!);
      }

      // 5) Cleanup bindings
      await WeightBridge.unbind(weightCtrl);
      await BatteryBridge.unbind(batteryCtrl);


      // 6) Reset Controllers' State
      weightCtrl.resetForNewOwner();
      batteryCtrl.resetState();

      // 7) Clear last controller ID
      await LastControllerStore.instance.clear();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bag removed successfully.'),
        ),
      );

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


  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
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
      body: ProGearBackground(
        child: SafeArea(
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

              //Delete Bag
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

              Text(
                'More settings coming soon…',
                style: AppTextStyles.secondary.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
