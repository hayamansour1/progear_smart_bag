import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/web.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:progear_smart_bag/core/services/bluetooth/blue_service.dart';
import 'package:progear_smart_bag/core/utils/logger.dart';

class BlueServiceImpl implements BlueService {
  final Logger _log = logger(BlueServiceImpl);

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
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

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
        _log.i('${device.platformName} is already connected');
      } else {
        _log.i("Connection error: $error");
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
  Future<BluetoothCharacteristic?> readCharacteristic(
      BluetoothDevice device) async {
    // get services
    List<BluetoothService> services = await discoverServices(device);
    BluetoothCharacteristic? targetChar;
    // UUIDs الخاصة بالجهاز (غيرها حسب جهازك)
    const String myServiceUUID = "0000180f-0000-1000-8000-00805f9b34fb";
    const String myCharUUID = "00002a19-0000-1000-8000-00805f9b34fb";

    for (var s in services) {
      _log.w("SERVICE: ${s.uuid}");

      for (var c in s.characteristics) {
        _log.w("   CHAR: ${c.uuid} | props: ${c.properties}");
      }
    }
    // ابحث عن الـ characteristic الصحيحة
    for (var service in services) {
      if (service.uuid.toString() == myServiceUUID) {
        for (var c in service.characteristics) {
          if (c.uuid.toString() == myCharUUID) {
            targetChar = c;
            break;
          }
        }
      }
    }
    if (targetChar == null) {
      _log.e("Characteristic not found");
      return null;
    }
    return targetChar;
  }
}
