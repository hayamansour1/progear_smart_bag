import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';
import 'package:progear_smart_bag/core/constants/app_images.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/features/bag/controllers/bluetooth_controller.dart';
import 'package:progear_smart_bag/features/bag/presentation/widgets/button_scan_search.dart';
import 'package:provider/provider.dart';

class BagStatusCard extends StatelessWidget {
  const BagStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controllerBluetooth = context.watch<BluetoothController>();
    return InkWell(
      onTap: () {
        if (controllerBluetooth.connectedDevice != null) {
          AwesomeDialog(
            dialogBackgroundColor: AppColors.backgroundLight,
            context: context,
            dialogType: DialogType.warning,
            animType: AnimType.scale,
            title: controllerBluetooth.connectedDevice!.remoteId.str,
            desc: 'Are you sure you want to disconnect?',
            btnCancelText: 'Cancel',
            btnOkText: 'Disconnect',
            btnCancelOnPress: () {},
            btnOkOnPress: () {
              controllerBluetooth
                  .disconnectDevice(controllerBluetooth.connectedDevice!);
              // Navigator.pop(context);
            },
          ).show();
        }
      },
      child: Container(
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
              height: 85,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    AppImages.logoBag,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
            if (controllerBluetooth.connectedDevice == null)
              ButtonScanSearch()
            else
              // name Device
              Row(
                spacing: AppSizes.sm,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // icon green connect
                  Icon(
                    Icons.bluetooth_connected,
                    color: Colors.greenAccent,
                  ),

                  Text(controllerBluetooth.connectedDevice?.remoteId.str ?? ''),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
