import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:progear_smart_bag/core/services/blue_service.dart';

class BlueServiceImpl implements BlueService {
  @override
  Future<void> startScan() async =>
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));

  @override
  Future<void> stopScan() async => FlutterBluePlus.stopScan();

  @override
  Stream<List<ScanResult>> get ScanResults => FlutterBluePlus.scanResults;

  @override
  Future<void> connect(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: true, license: License.free);
    } catch (e) {
      if (e.toString().contains('already connected')) {
        // await device.disconnect();
        // await device.connect(autoConnect: true, license: License.free);
        print('${device.platformName} is already connected');
      } else {
        print("Connection error: $e");
      }
    }
  }

  @override
  Future<void> disconnect(BluetoothDevice device) async {
    await device.disconnect();
    print('${device.platformName} is disconnected');
  }

  @override
  Future<List<BluetoothService>> discoverServices(BluetoothDevice device) {
    return device.discoverServices();
  }

  @override
  bool isConnected(BluetoothDevice device) {
    return device.isConnected;
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
