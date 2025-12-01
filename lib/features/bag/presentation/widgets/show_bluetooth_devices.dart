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

class ShowBluetoothDevices extends StatelessWidget {
  const ShowBluetoothDevices({super.key});

  // الدالة اللي تمسك الكلك على ديفايس واحد
  Future<void> _handleDeviceTap({
    required BuildContext context,
    required BluetoothController btCtrl,
    required BluetoothDevice device,
  }) async {
    // لو الجهاز هذا قاعد يعمل connect/disconnect حاليًا → نتجاهل التاب
    if (btCtrl.isDeviceLoading(device.remoteId.str)) return;

    // لو متصل حاليًا → نفصل فقط ونرجع
    if (device.isConnected) {
      await btCtrl.disconnectDevice(device);
      return;
    }

    // نجيب الكنترولرز قبل ما نبدأ awaits عشان ما نرجع للـ context بعدين
    final weightCtrl = context.read<WeightController>();
    final batteryCtrl = context.read<BatteryController>();
    final sb = Supabase.instance.client;

    try {
      // نوقف الاسكان قبل الاتصال
      await btCtrl.stopScan();

      // 1) نعمل connect عادي
      await btCtrl.connectDevice(device);
      final cid = device.remoteId.str;

      // 2) enforce ownership عبر ensure_controller
      try {
        await sb.rpc('ensure_controller', params: {
          'p_controller': cid,
        });
      } on PostgrestException catch (e) {
        final msg = e.message.toLowerCase();

        // نتحقق من النص اللي كتبناه في الـ function
        final isInUse = msg.contains('already paired with another account');

        if (isInUse) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This bag is already paired with another account.\n'
                  'Ask the current owner to remove it from Settings > Remove bag, '
                  'then try again.',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
          // نفصل الجهاز ونرجع
          await btCtrl.disconnectDevice(device);
          return;
        } else {
          // خطأ آخر من Supabase
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to pair bag: ${e.message}'),
              ),
            );
          }
          await btCtrl.disconnectDevice(device);
          return;
        }
      }

      // 3) نجيب الـ characteristic حق الـ notify
      final characteristic = await btCtrl.getNotifyCharacteristic();
      if (characteristic == null) {
        debugPrint('❌ No notify characteristic found');
        await btCtrl.disconnectDevice(device);
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

      // منطق expectedWeight والهاندلينق الداخلي صار في WeightController/DB

      // 5) نقفل شيت الأجهزة
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e, st) {
      debugPrint('❌ Error in _handleDeviceTap: $e\n$st');
      // لو صار خطأ في أي خطوة نحاول نفصل الجهاز احتياطًا
      try {
        if (device.isConnected) {
          await btCtrl.disconnectDevice(device);
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothController>(
      builder: (context, controller, child) {
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
                    width: (AppSizes.xl * 2),
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
                          'No devices found',
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
