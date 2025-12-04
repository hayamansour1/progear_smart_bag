import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:progear_smart_bag/core/services/bluetooth/blue_service.dart';
import 'package:progear_smart_bag/core/utils/logger.dart';
import 'package:progear_smart_bag/core/debug/debug_flags.dart';

class BlueServiceImpl implements BlueService {
  final Logger _log = logger(BlueServiceImpl);

  static final Guid _svcUart =
      Guid('6E400001-B5A3-F393-E0A9-E50E24DCCA9E'); // SERVICE
  static final Guid _txUart =
      Guid('6E400003-B5A3-F393-E0A9-E50E24DCCA9E'); // TX (notify)

  /// Request bluetooth permission
  Future<void> _checkPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();
  }

  /// Ensure bluetooth on
  Future<void> _ensureBluetoothOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      DebugFlags.logBle('Bluetooth is OFF → opening settings');
      await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
    }
  }

  @override
  Future<void> startScan() async {
    DebugFlags.logBle('startScan() called');
    await _checkPermissions();
    await _ensureBluetoothOn();
    DebugFlags.logBle('FlutterBluePlus.startScan()');
    await FlutterBluePlus.startScan();
  }

  @override
  Future<void> stopScan() async {
    DebugFlags.logBle('stopScan() called');
    await FlutterBluePlus.stopScan();
  }

  @override
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  @override
  Future<void> connect(BluetoothDevice device) async {
    try {
      DebugFlags.logBle('connect -> ${device.remoteId}');

      await device
          .connect(
            autoConnect: true,
            license: License.free,
            mtu: null,
          )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException("Connection timeout");
        },
      );

      await device.connectionState
          .firstWhere((s) => s == BluetoothConnectionState.connected);

      try {
        final mtu = await device.requestMtu(185);
        DebugFlags.logBle('MTU negotiated: $mtu');
      } catch (e) {
        DebugFlags.logBle('requestMtu failed: $e');
      }
    } catch (error) {
      if (error.toString().contains('already connected')) {
        DebugFlags.logBle('${device.platformName} is already connected');
      } else {
        _log.e("Connection error: $error");
      }
    }
  }

  @override
  Future<void> disconnect(BluetoothDevice device) async {
    DebugFlags.logBle('disconnect -> ${device.remoteId}');
    await device.disconnect();
  }

  @override
  bool isConnected(BluetoothDevice device) {
    return device.isConnected;
  }

  @override
  Future<List<BluetoothService>> discoverServices(
      BluetoothDevice device) async {
    DebugFlags.logBle('discoverServices -> ${device.remoteId}');
    return device.discoverServices();
  }

  @override
  Future<BluetoothCharacteristic?> readCharacteristic(
    BluetoothDevice device,
  ) async {
    DebugFlags.logBle('readCharacteristic: start for ${device.remoteId.str}');

    final services = await discoverServices(device);

    DebugFlags.logBle('--- GATT table for ${device.remoteId.str} ---');
    for (final s in services) {
      DebugFlags.logBle('SERVICE: ${s.uuid}');
      for (final c in s.characteristics) {
        DebugFlags.logBle(
          '  CHAR: ${c.uuid} '
          'notify=${c.properties.notify} '
          'indicate=${c.properties.indicate} '
          'read=${c.properties.read} '
          'write=${c.properties.write} '
          'writeWithoutResp=${c.properties.writeWithoutResponse}',
        );
      }
    }

    BluetoothService? uartService;
    for (final s in services) {
      if (s.uuid == _svcUart) {
        uartService = s;
        break;
      }
    }

    if (uartService == null) {
      DebugFlags.logBle('❌ UART service not found ($_svcUart)');
      return null;
    }

    BluetoothCharacteristic? txChar;
    for (final c in uartService.characteristics) {
      if (c.uuid == _txUart) {
        txChar = c;
        break;
      }
    }

    if (txChar == null) {
      DebugFlags.logBle('❌ UART TX characteristic not found ($_txUart)');
      return null;
    }

    DebugFlags.logBle('✅ Using TX characteristic: ${txChar.uuid}');
    return txChar;
  }
}
