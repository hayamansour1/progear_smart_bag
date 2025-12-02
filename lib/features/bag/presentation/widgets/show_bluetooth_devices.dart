// lib/features/bag/presentation/widgets/show_bluetooth_devices.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:progear_smart_bag/core/constants/app_colors.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';

import 'package:progear_smart_bag/features/bag/controllers/bluetooth_controller.dart';
import 'package:progear_smart_bag/features/weight/logic/weight_controller.dart';
import 'package:progear_smart_bag/features/home/logic/battery_controller.dart';
import 'package:progear_smart_bag/features/weight/logic/weight_bridge.dart';
import 'package:progear_smart_bag/features/home/logic/battery_bridge.dart';
import 'package:progear_smart_bag/features/home/presentation/widgets/set_expected_weight_sheet.dart';

/// Sheet لعرض أجهزة البلوتوث.
/// [parentContext] ما عاد نستخدمه داخليًا، بس مخليه عشان ما يكسر الاستدعاءات الحالية.
class ShowBluetoothDevices extends StatelessWidget {
  final BuildContext parentContext;

  const ShowBluetoothDevices({
    super.key,
    required this.parentContext,
  });

  // === tap on single device ===
  Future<void> _handleDeviceTap({
    required BuildContext context,
    required BluetoothController btCtrl,
    required BluetoothDevice device,
  }) async {
    // نجيب ScaffoldMessenger و الكنترولرز من نفس context حاليًا وهو ما زال mounted
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final weightCtrl = context.read<WeightController>();
    final batteryCtrl = context.read<BatteryController>();
    final sb = Supabase.instance.client;

    // لو الجهاز هذا قاعد يعمل connect/disconnect حاليًا → نتجاهل التاب
    if (btCtrl.isDeviceLoading(device.remoteId.str)) return;

    // لو متصل حاليًا → نفصل فقط ونرجع
    if (device.isConnected) {
      await btCtrl.disconnectDevice(device);
      return;
    }

    try {
      // نوقف الاسكان قبل الاتصال
      await btCtrl.stopScan();

      // 1) connect
      await btCtrl.connectDevice(device);
      final cid = device.remoteId.str;

      // 2) enforce ownership via ensure_controller
      try {
        await sb.rpc('ensure_controller', params: {
          'p_controller': cid,
        });
      } on PostgrestException catch (e) {
        final msg = e.message.toString().toLowerCase();
        final detail = (e.details?.toString() ?? '').toLowerCase();

        final isInUse = msg.contains('controller_in_use') ||
            detail.contains('already paired with another account');

        if (isInUse) {
          await btCtrl.disconnectDevice(device);

          scaffoldMessenger
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                backgroundColor: Colors.redAccent.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                content: const Text(
                  'This bag is already paired with another account.\n'
                  'Ask the current owner to remove it from: Settings → Remove bag, '
                  'then try again.',
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          return;
        } else {
          await btCtrl.disconnectDevice(device);

          final detailStr = e.details?.toString();
          final userMsg = (detailStr != null && detailStr.isNotEmpty)
              ? detailStr
              : e.message.toString();

          scaffoldMessenger
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                content: Text('Failed to pair bag: $userMsg'),
                duration: const Duration(seconds: 4),
              ),
            );
          return;
        }
      }

      // 3) characteristic حق الـ notify
      final characteristic = await btCtrl.getNotifyCharacteristic();
      if (characteristic == null) {
        debugPrint('❌ No notify characteristic found');
        await btCtrl.disconnectDevice(device);

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            content: Text('No data characteristic found on this device.'),
          ),
        );
        return;
      }

      // 4) نربط Weight + Battery بالـ BLE
      await WeightBridge.bind(
        weightCtrl,
        characteristic,
        controllerID: cid,
      );

      await BatteryBridge.bind(
        batteryCtrl,
        characteristic,
        controllerID: cid,
      );

      // 5) افتح شيت SetExpectedWeight فوق شيت الأجهزة
      debugPrint(
          '⚙️ ShowBluetoothDevices: opening SetExpectedWeightSheet for $cid');

      final saved = await showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SetExpectedWeightSheet(controllerID: cid),
      );

      // لو رجع true نطلع SnackBar بسيط من نفس الـ Scaffold
      if (saved == true) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            content: Text('Bag weight saved as your default weight.'),
          ),
        );
      }

      // في كل الأحوال بعد ما يخلص شيت الوزن نقفل شيت البلوتوث نفسه
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      debugPrint('❌ Error in _handleDeviceTap: $e\n$st');
      try {
        if (device.isConnected) {
          await btCtrl.disconnectDevice(device);
        }
      } catch (_) {}

      // نستخدم scaffoldMessenger اللي أخذناه قبل أي pop
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          content: Text('Something went wrong while connecting to the bag.'),
        ),
      );

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothController>(
      builder: (context, controller, child) {
        // Auto-start scan لما تفتح الشيت
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!controller.isScanning && controller.devices.isEmpty) {
            controller.startScan();
          }
        });

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.md),
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.md),
            ),
          ),
          child: Column(
            spacing: AppSizes.md,
            children: [
              // ======= Header row =======
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    style: const ButtonStyle(
                      padding: WidgetStatePropertyAll(EdgeInsets.zero),
                      minimumSize: WidgetStatePropertyAll(Size.zero),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  Container(
                    width: AppSizes.xl * 2,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  if (controller.isScanning)
                    const SpinKitCircle(
                      color: AppColors.primaryBlue,
                      size: 25,
                    )
                  else
                    IconButton(
                      style: const ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        minimumSize: WidgetStatePropertyAll(Size.zero),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: controller.startScan,
                      icon: const Icon(Icons.refresh),
                    ),
                ],
              ),

              const Text(
                'Select Bluetooth Device',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // ======= Devices list =======
              Expanded(
                child: controller.devices.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: AppSizes.md),
                        child: Text(
                          'Searching for nearby devices…',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppSizes.fontLg,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: controller.devices.length,
                        itemBuilder: (context, index) {
                          final device = controller.devices[index].device;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                              vertical: AppSizes.sm,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.sm),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: AppSizes.sm,
                                horizontal: AppSizes.md,
                              ),
                              title: Text(
                                device.platformName.isNotEmpty
                                    ? device.platformName
                                    : device.remoteId.str,
                              ),
                              subtitle: device.isConnected
                                  ? const Text('Connected')
                                  : null,
                              trailing: controller
                                      .isDeviceLoading(device.remoteId.str)
                                  ? const SizedBox(
                                      width: 40,
                                      child: SpinKitWave(
                                        size: 30,
                                        type: SpinKitWaveType.end,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : device.isConnected
                                      ? const Icon(
                                          Icons.link_off,
                                          color: Colors.red,
                                        )
                                      : const Icon(
                                          Icons.link,
                                          color: Colors.green,
                                        ),
                              onTap: () => _handleDeviceTap(
                                context: context,
                                btCtrl: controller,
                                device: device,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
