import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class BlueService {
  /// [startScan] start scanning for bluetooth devices
  Future<void> startScan();

  /// [stopScan] stop scanning for bluetooth devices
  Future<void> stopScan();

  /// [scanResults] stream of bluetooth devices found
  Stream<List<ScanResult>> get scanResults;

  /// [connect] connect to bluetooth device
  Future<void> connect(BluetoothDevice device);

  /// [disconnect] disconnect from bluetooth device
  Future<void> disconnect(BluetoothDevice device);

  /// [discoverServices] discover services of bluetooth device
  Future<List<BluetoothService>> discoverServices(BluetoothDevice device);

  /// [isConnected] check if bluetooth device is connected
  bool isConnected(BluetoothDevice device);

  /// [readCharacteristic] read characteristic of bluetooth device
  Future<BluetoothCharacteristic?> readCharacteristic(BluetoothDevice device);
}
