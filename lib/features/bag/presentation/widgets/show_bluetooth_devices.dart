import 'package:flutter/material.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/features/bag/controllers/bluetooth_controller.dart';
import 'package:provider/provider.dart';

class ShowBluetoothDevices extends StatelessWidget {
  const ShowBluetoothDevices({super.key});

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
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppSizes.md)),
          ),
          child: Column(
            spacing: AppSizes.md,
            children: [
              // List of devices
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Text(
                'Select Bluetooth Device',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // show list of devices
              Expanded(
                child: controller.devices.isEmpty
                    ? Padding(
                        padding: EdgeInsets.only(top: AppSizes.md),
                        child: Text(
                          'No devices found',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppSizes.fontLg),
                        ),
                      )
                    : ListView.builder(
                        itemCount: controller.devices.length,
                        itemBuilder: (context, index) {
                          final device = controller.devices[index].device;
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(vertical: AppSizes.sm),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.sm),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                vertical: AppSizes.sm,
                                horizontal: AppSizes.md,
                              ),
                              title: Text(device.platformName.isNotEmpty
                                  ? device.platformName
                                  : device.remoteId.toString()),
                              subtitle: Text(device.remoteId.toString()),
                              trailing: device.isConnected
                                  ? const Icon(
                                      Icons.link_off,
                                      color: Colors.red,
                                    )
                                  : const Icon(Icons.link, color: Colors.green),
                              onTap: () {
                                if (device.isConnected) {
                                  controller.disconnectDevice(device);
                                } else {
                                  controller.connectDevice(device);
                                }
                                Navigator.pop(context); // close sheet
                              },
                            ),
                          );
                        },
                      ),
              )
            ],
          ),
        );
      },
    );
  }
}
