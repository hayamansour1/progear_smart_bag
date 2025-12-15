import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:progear_smart_bag/core/constants/app_colors.dart';
import 'package:progear_smart_bag/core/constants/app_sizes.dart';
import 'package:progear_smart_bag/core/services/bluetooth/blue_service_impl.dart';
import 'package:progear_smart_bag/core/utils/logger.dart';
import 'package:progear_smart_bag/core/debug/debug_flags.dart';
import 'package:progear_smart_bag/features/activity/data/last_controller_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BluetoothController extends ChangeNotifier {
  final Logger _log = logger(BluetoothController);
  final BlueServiceImpl _blueServiceImpl;

  BluetoothController(this._blueServiceImpl) {
    _init();
  }

  // ----- scanning state -----
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  // per-device loading indicator
  final Map<String, bool> _loadingDevices = {};
  bool isDeviceLoading(String deviceId) => _loadingDevices[deviceId] ?? false;

  void _setDeviceLoading(String deviceId, bool isLoading) {
    _loadingDevices[deviceId] = isLoading;
    notifyListeners();
  }

  // ----- adapter state -----
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  BluetoothAdapterState get adapterState => _adapterState;

  // ----- devices list -----
  List<ScanResult> _devices = [];
  List<ScanResult> get devices => _devices;

  // ----- connected device -----
  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // ----- subscriptions -----
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _stateSubscription;

  void _init() {
    DebugFlags.logBle('BluetoothController._init()');

    //  On/Off
    _stateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      DebugFlags.logBle('Adapter state changed: $state');
      notifyListeners();
    });

    _scanSubscription = _blueServiceImpl.scanResults.listen((results) {
      _devices = results;
      DebugFlags.logBle('scanResults updated: ${results.length} devices found');
      notifyListeners();
    });
  }

  // ----- scan control -----

  Future<void> startScan() async {
    try {
      DebugFlags.logBle('startScan() from controller');
      _isScanning = true;
      notifyListeners();

      await _blueServiceImpl.startScan();

      Future.delayed(const Duration(minutes: 1), () async {
        if (_isScanning) {
          DebugFlags.logBle('Auto stop scan after 1 minute');
          await _blueServiceImpl.stopScan();
          _isScanning = false;
          notifyListeners();
        }
      });
    } catch (e, st) {
      _log.e('startScan error: $e\n$st');
      _isScanning = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> stopScan() async {
    try {
      DebugFlags.logBle('stopScan() from controller');
      _isScanning = false;
      notifyListeners();
      await _blueServiceImpl.stopScan();
    } catch (e, st) {
      _log.e('stopScan error: $e\n$st');
      rethrow;
    }
  }

  List<BluetoothDevice> getConnectedDevices() {
    return FlutterBluePlus.connectedDevices;
  }

  // ----- connect / disconnect -----

  Future<void> connectDevice(BluetoothDevice device) async {
    final sb = Supabase.instance.client;

    try {
      final id = device.remoteId.str;
      DebugFlags.logBle('connectDevice -> $id');
      _setDeviceLoading(id, true);

      for (var result in _devices) {
        if (result.device.isConnected &&
            result.device.remoteId != device.remoteId) {
          DebugFlags.logBle(
              'Disconnecting other connected device: ${result.device.remoteId.str}');
          await _blueServiceImpl.disconnect(result.device);
        }
      }

      // connect
      await _blueServiceImpl.connect(device);

      await device.connectionState
          .firstWhere((s) => s == BluetoothConnectionState.connected)
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          Fluttertoast.showToast(
            msg: "Connection failed. Please try again",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: AppColors.backgroundLight,
            textColor: Colors.white,
            fontSize: AppSizes.fontLg,
          );
          throw TimeoutException('Connection timeout');
        },
      );

      _connectedDevice = device;
      DebugFlags.logBle('Device connected: $id');
      notifyListeners();

      final cid = device.remoteId.str;

      try {
        _log.t('Calling ensure_controller for $cid');
        await sb.rpc('ensure_controller', params: {
          'p_controller': cid,
        });

        _log.t('Saving last controller: $cid');
        await LastControllerStore.instance.setLastControllerID(cid);
      } catch (e, st) {
        _log.w('ensure_controller failed (soft): $e\n$st');
      }
    } catch (e, st) {
      _log.e('Connect error: $e\n$st');
      _connectedDevice = null;
      notifyListeners();
      rethrow;
    } finally {
      _setDeviceLoading(device.remoteId.str, false);
    }
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      final id = device.remoteId.str;
      DebugFlags.logBle('disconnectDevice -> $id');
      _setDeviceLoading(id, true);
      await _blueServiceImpl.disconnect(device);
      if (_connectedDevice?.remoteId == device.remoteId) {
        _connectedDevice = null;
        notifyListeners();
      }
    } catch (e, st) {
      _log.e('disconnectDevice error: $e\n$st');
      rethrow;
    } finally {
      _setDeviceLoading(device.remoteId.str, false);
    }
  }

  Future<BluetoothCharacteristic?> getNotifyCharacteristic() async {
    if (_connectedDevice == null) {
      _log.w('getNotifyCharacteristic: no connected device');
      return null;
    }

    final device = _connectedDevice!;
    final cid = device.remoteId.str;

    _log.t('getNotifyCharacteristic: for controllerID = $cid');

    final characteristic = await _blueServiceImpl.readCharacteristic(device);

    if (characteristic == null) {
      _log.e('getNotifyCharacteristic: characteristic is null');
    } else {
      _log.t(
          'getNotifyCharacteristic: using char ${characteristic.uuid} for $cid');
    }

    return characteristic;
  }

  @override
  void dispose() {
    DebugFlags.logBle('BluetoothController.dispose() called');
    _scanSubscription?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }
}
