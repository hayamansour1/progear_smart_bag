import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:progear_smart_bag/core/services/bluetooth/blue_service_impl.dart';

class BluetoothController extends ChangeNotifier {
  // blue service
  final BlueServiceImpl _blueServiceImpl;

  // constructor init blue service
  BluetoothController(this._blueServiceImpl) {
    _init();
  }

  // handle scanning state
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  // handle bluetooth state on or off
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BluetoothAdapterState get adapterState => _adapterState;

  // handle devices
  List<ScanResult> _devices = [];
  List<ScanResult> get devices => _devices;

  // handle subscription state scanning
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // handle subscription state bluetooth
  StreamSubscription<BluetoothAdapterState>? _stateSubscription;

  /// check state bluetooth on or off as Stream
  /// check state scanning bluetooth devices as Stream
  void _init() {
    // following state bluetooth
    _stateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      // for ui reBuild when bluetooth on or off
      notifyListeners();
    });

    // following state scanning
    _scanSubscription = _blueServiceImpl.ScanResults.listen((results) {
      _devices = results;
      // change state scanning and for ui reBuild
      notifyListeners();
    });
  }

  /// [startScan] start scanning
  Future<void> startScan() async {
    try {
      _isScanning = true;
      notifyListeners();
      await _blueServiceImpl.startScan();
      // check state scanning stop
    } catch (e) {
      // stop loading
      _isScanning = false;
      notifyListeners();
      rethrow;
    }
  }

  /// [stopScan] stop scanning
  Future<void> stopScan() async {
    try {
      _isScanning = false;
      notifyListeners();
      await _blueServiceImpl.stopScan();
    } catch (e) {
      rethrow;
    }
  }

  /// [connectDevice] connect device
  Future<void> connectDevice(BluetoothDevice device) async {
    try {
      await _blueServiceImpl.connect(device);
    } catch (e) {
      debugPrint('Connect error: $e');
      rethrow;
    }
  }

  /// [disconnectDevice] disconnect device
  Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await _blueServiceImpl.disconnect(device);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    // on or off bluetooth cancel stream
    _stateSubscription?.cancel();
    super.dispose();
  }
}
