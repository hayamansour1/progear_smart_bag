import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:progear_smart_bag/core/services/bluetooth/blue_service.dart';

class BlueServiceImpl implements BlueService {
  /// Request bluetooth permission
  Future<void> _checkPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();
  }

  /// Ensure bluetooth on
  Future<void> _ensureBluetoothOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    // bluetooth off
    if (state != BluetoothAdapterState.on) {
      // handle this open app settings dialog here bluetooth
      await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
    }
  }

  @override
  Future<void> startScan() async {
    // step one check permission
    await _checkPermissions();
    // step two ensure bluetooth on
    await _ensureBluetoothOn();
    // step three start scan
    await FlutterBluePlus.startScan();
  }

  @override
  Future<void> stopScan() async => await FlutterBluePlus.stopScan();

  @override
  Stream<List<ScanResult>> get ScanResults => FlutterBluePlus.scanResults;

  @override
  Future<void> connect(BluetoothDevice device) async {
    try {
      await device
          .connect(autoConnect: true, license: License.free, mtu: null)
          .timeout(Duration(seconds: 30), onTimeout: () {
        throw TimeoutException("Connection timeout");
      });
    } catch (error) {
      if (error.toString().contains('already connected')) {
        // await device.disconnect();
        // await device.connect(autoConnect: true, license: License.free);
        print('${device.platformName} is already connected');
      } else {
        print("Connection error: $error");
      }
    }
  }

  @override
  Future<void> disconnect(BluetoothDevice device) async {
    await device.disconnect();
  }

  @override
  bool isConnected(BluetoothDevice device) {
    return device.isConnected;
  }

  @override
  Future<List<BluetoothService>> discoverServices(BluetoothDevice device) {
    return device.discoverServices();
  }

  @override
  Stream<List<int>> readCharacteristic(
      BluetoothCharacteristic characteristic) async* {
    await characteristic.setNotifyValue(true);
    await for (var value in characteristic.lastValueStream) {
      yield value;
    }
  }
}
