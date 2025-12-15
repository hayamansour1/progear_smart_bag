import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';
import 'package:progear_smart_bag/core/constants/app_images.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/constants/app_text_styles.dart';
import 'package:progear_smart_bag/features/bag/controllers/bluetooth_controller.dart';
// import 'package:progear_smart_bag/features/bag/presentation/widgets/button_scan_search.dart';
import 'package:provider/provider.dart';

class AlertBagConnection extends StatelessWidget {
  const AlertBagConnection({super.key});

  @override
  Widget build(BuildContext context) {
    final controllerBluetooth = context.watch<BluetoothController>();
    if (controllerBluetooth.connectedDevice != null) {
      // pop if already connected close alert
      Navigator.pop(context);
    }
    return AlertDialog(
      elevation: 30,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Bag Connection', style: AppTextStyles.heading2),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSizes.lg,
        children: [
          const Text(
            'Please activate Bluetooth on your device and make sure the bag is nearby so you can connect to it.',
            textAlign: TextAlign.center,
          ),

          // Image
          Stack(
            children: [
              Image.asset(
                AppImages.logoBag,
                height: 100,
                fit: BoxFit.contain,
              ),
              Positioned(child: Icon(Icons.bluetooth))
            ],
          ),
        ],
      ),
      // actionsAlignment: MainAxisAlignment.center,
      // actions: [ButtonScanSearch()],
    );
  }
}
