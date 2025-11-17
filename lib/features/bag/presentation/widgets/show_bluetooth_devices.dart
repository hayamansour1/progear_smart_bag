import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
              // Line divider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        minimumSize: WidgetStatePropertyAll(Size.zero),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close)),
                  Container(
                    width: (AppSizes.xl * 2),
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // loading scan
                  if (controller.isScanning)
                    SpinKitCircle(
                      color: AppColors.primaryBlue,
                      size: 25,
                    )
                  else
                    IconButton(
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        minimumSize: WidgetStatePropertyAll(Size.zero),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: controller.startScan,
                      icon: Icon(Icons.refresh),
                    ),
                ],
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
                                  : device.remoteId.str),
                              subtitle:
                                  device.isConnected ? Text('Connected') : null,
                              trailing: controller
                                      .isDeviceLoading(device.remoteId.str)
                                  ? SizedBox(
                                      width: 40,
                                      child: SpinKitWave(
                                        size: 30,
                                        type: SpinKitWaveType.end,
                                        color: Colors.grey[300],
                                      ),
                                    )
                                  : device.isConnected
                                      ? const Icon(
                                          Icons.link_off,
                                          color: Colors.red,
                                        )
                                      : const Icon(Icons.link,
                                          color: Colors.green),
                              onTap: () async {
                                if (device.isConnected) {
                                  await controller.disconnectDevice(device);
                                  // Navigator.pop(context); // close sheet
                                } else {
                                  await controller.connectDevice(
                                      device, context);
                                  // Navigator.pop(context); // close sheet
                                }
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
