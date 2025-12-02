// lib/features/bag/presentation/widgets/button_scan_search.dart
import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';
import 'package:progear_smart_bag/features/bag/controllers/bluetooth_controller.dart';
import 'package:progear_smart_bag/features/bag/presentation/widgets/show_bluetooth_devices.dart';
import 'package:provider/provider.dart';

class ButtonScanSearch extends StatelessWidget {
  const ButtonScanSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        backgroundColor: const WidgetStatePropertyAll(AppColors.primaryBlue),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      onPressed: () {
        context.read<BluetoothController>().startScan();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => ShowBluetoothDevices(
            parentContext: context,
          ),
        );
      },
      child: const Text('start scan'),
    );
  }
}
