import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';

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

  // loading for connection
  final Map<String, bool> _loadingDevices = {};
  bool isDeviceLoading(String deviceId) => _loadingDevices[deviceId] ?? false;

  void _setDeviceLoading(String deviceId, bool isLoading) {
    _loadingDevices[deviceId] = isLoading;
    notifyListeners();
  }

  // handle bluetooth state on or off
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BluetoothAdapterState get adapterState => _adapterState;

  // handle devices
  List<ScanResult> _devices = [];
  List<ScanResult> get devices => _devices;

  // handle connected devices
  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

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

      // TimeOut
      Future.delayed(Duration(minutes: 1), () async {
        if (_isScanning) {
          await _blueServiceImpl.stopScan();
          _isScanning = false;
          notifyListeners();
        }
      });

      // check state scanning stop
    } catch (e) {
      // stop loading
      _isScanning = false;
      notifyListeners();
      rethrow;
    }
  }

  /// [getConnectedDevices] get connected devices
  List<BluetoothDevice> getConnectedDevices() {
    return FlutterBluePlus.connectedDevices;
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
      _setDeviceLoading(device.remoteId.str, true);
      // step one disconnect another device
      for (var result in _devices) {
        if (await result.device.isConnected &&
            result.device.remoteId != device.remoteId) {
          await _blueServiceImpl.disconnect(result.device);
        }
      }

      await _blueServiceImpl.connect(device);
      // step two wait device connected
      await device.connectionState
          .firstWhere((s) => s == BluetoothConnectionState.connected)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        Fluttertoast.showToast(
            msg: "Connection failed. Please try again",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: AppColors.backgroundLight,
            textColor: Colors.white,
            fontSize: AppSizes.fontLg);
        throw TimeoutException('Connection timeout');
      });
      _connectedDevice = device;
      notifyListeners();
    } catch (e) {
      debugPrint('Connect error: $e');

      _connectedDevice = null;
      notifyListeners();
      rethrow;
    } finally {
      _setDeviceLoading(device.remoteId.str, false);
    }
  }

  /// [disconnectDevice] disconnect device
  Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      _setDeviceLoading(device.remoteId.str, true);
      await _blueServiceImpl.disconnect(device);
      if (_connectedDevice?.remoteId == device.remoteId) {
        _connectedDevice = null;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    } finally {
      _setDeviceLoading(device.remoteId.str, false);
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
