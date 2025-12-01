import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:progear_smart_bag/core/services/parser/bag_parser.dart';
import 'package:progear_smart_bag/features/home/data/battery_repository.dart';
import 'package:progear_smart_bag/features/activity/data/activity_seen_store.dart';
import 'package:progear_smart_bag/core/debug/debug_flags.dart';

/// BatteryController
/// Owns battery state + BLE parsing + optional DB sync.
class BatteryController extends ChangeNotifier {
  final BagParser _parser;
  final BatteryRepository? _repo;

  String? _controllerID;

  void setControllerID(String id) {
    _controllerID = id;
  }

  BatteryController(
    this._parser, {
    BatteryRepository? repository,
    String? controllerID,
  })  : _repo = repository,
        _controllerID = controllerID;

  // نبدأ بـ -1 عشان أول قراءة دايمًا تعتبر "تغيير"
  int _percent = -1;
  bool _isCharging = false;
  DateTime? _lastUpdated;

  int get percent => _percent;
  bool get isCharging => _isCharging;
  DateTime? get lastUpdated => _lastUpdated;

  StreamSubscription<String>? _sub;
  DateTime _lastUploadAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Minimum spacing between uploads to DB.
  final Duration _minUploadGap = const Duration(seconds: 8);

  /// boot(): hydrate from DB once (nice UX before BLE is live)
  Future<void> boot() async {
    if (_repo == null || _controllerID == null) return;
    try {
      final latest = await _repo!.getStatus(controllerID: _controllerID!);
      if (latest != null) {
        _percent = latest.percent.clamp(0, 100);
        _isCharging = latest.charging;
        _lastUpdated = latest.updatedAt;
        notifyListeners();
      }
    } catch (e) {
      DebugFlags.logBattery('Battery boot() failed: $e');
    }
  }

  /// Bind BLE notify characteristic to BagParser (called via BatteryBridge.bind)
  Future<void> bindToCharacteristic(
    BluetoothCharacteristic characteristic,
  ) async {
    await _parser.bind(characteristic);
    await _sub?.cancel();
    _sub = _parser.stream.listen(_onLine, onError: (e) {
      DebugFlags.logBattery('BatteryController stream error: $e');
    });
  }

  Future<void> unbind() async {
    await _sub?.cancel();
    _sub = null;
    await _parser.unbind();
  }

  /// Apply a new reading (either from BLE or from tests)
  Future<void> applyReading({
    required int percent,
    required bool charging,
    DateTime? timestamp,
  }) async {
    final prev = _percent; // keep previous value

    final clamped = percent.clamp(0, 100);
    final isFirst = (_percent < 0);

    final changed = isFirst ||
        (clamped != _percent) ||
        (charging != _isCharging);

    _percent = clamped;
    _isCharging = charging;
    _lastUpdated = timestamp ?? DateTime.now();

    if (changed) {
      notifyListeners();
      _maybeUploadToDB();
    }

    // Fire "battery_low" only when crossing from >=21% down to <=20% (مو أول مرة)
    final crossedLow = (!isFirst && prev >= 21 && _percent <= 20);
    if (crossedLow) {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;
      if (uid != null && _repo != null && _controllerID != null) {
        await sb.rpc('insert_notification', params: {
          'p_controller': _controllerID!,
          'p_user': uid,
          'p_kind': 'battery_low',
          'p_title': 'Battery low',
          'p_message': 'Bag battery is at $_percent%.',
          'p_severity': 'warn',
          'p_meta': {'percent': _percent, 'charging': _isCharging},
        });

        // Raise local unread flag so header dot appears instantly
        await ActivitySeenStore.instance.bumpUnread(_controllerID!);
      }
    }
  }

  // ---- Parsing logic (BLE text frames) ----
  void _onLine(String line) {
    DebugFlags.logBattery('BatteryController raw: $line');

    final t = line.trim();
    if (t.isEmpty) return;

    // نفصل TAG:payload لو كانت BATTERY:...
    String payload = t;
    final idx = t.indexOf(':');
    if (idx > 0 &&
        (t.startsWith('BATTERY') ||
            t.startsWith('BAT:') ||
            t.startsWith('BATT:'))) {
      payload = t.substring(idx + 1).trim();
    }

    int? p;
    bool? chg;

    // أولاً نحاول JSON: {"percent":80,"chg":1}
    if (payload.startsWith('{') && payload.endsWith('}')) {
      try {
        final m = jsonDecode(payload) as Map<String, dynamic>;
        p = _readInt(
          m['percent'] ?? m['pct'] ?? m['bat'] ?? m['battery'],
        );
        chg = _readBool(m['chg'] ?? m['charging']);
        DebugFlags.logBattery('Battery JSON parsed: p=$p, chg=$chg');
      } catch (e) {
        DebugFlags.logBattery('BatteryController JSON parse error: $e');
      }
    }

    // fallback لصيغ نصية ثانية لو احتجناها مستقبلاً
    p ??= _extractInt(
      payload,
      RegExp(r'(?:BAT|BATT|BATTERY)\s*[:=]\s*(\d{1,3})'),
    );
    chg ??= _extractBool(
      payload,
      RegExp(
        r'(?:CHG|CHARGING)\s*[:=]\s*([01]|true|false)',
        caseSensitive: false,
      ),
    );

    // لو مو رسالة بطارية (زي WEIGHT_DATA) طنّشيها
    if (p == null && chg == null) {
      return;
    }

    applyReading(
      percent: p ?? _percent,
      charging: chg ?? _isCharging,
    );
  }

  int? _readInt(dynamic v) => v == null ? null : int.tryParse(v.toString());
  bool? _readBool(dynamic v) {
    if (v == null) return null;
    final s = v.toString().toLowerCase();
    return (s == '1' || s == 'true')
        ? true
        : (s == '0' || s == 'false')
            ? false
            : null;
  }

  int? _extractInt(String src, RegExp re) {
    final m = re.firstMatch(src);
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  bool? _extractBool(String src, RegExp re) {
    final m = re.firstMatch(src);
    if (m == null) return null;
    final raw = m.group(1)!.toLowerCase();
    return raw == '1' || raw == 'true';
  }

  // ---- DB sync ----
  Future<void> _maybeUploadToDB() async {
    // Only sync if repository + controllerID are provided
    if (_repo == null || _controllerID == null) {
      DebugFlags.logBattery(
          'BatteryController._maybeUploadToDB: repo=$_repo, controllerID=$_controllerID -> skip');
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastUploadAt) < _minUploadGap) return;
    _lastUploadAt = now;

    try {
      await _repo!.setStatus(
        controllerID: _controllerID!,
        percent: _percent,
        charging: _isCharging,
      );
      DebugFlags.logBattery(
          'BatteryController._maybeUploadToDB: updated DB to $_percent%, charging=$_isCharging');
    } catch (e) {
      DebugFlags.logBattery('set_battery_status failed: $e');
    }
  }

  /// نستخدمها وقت الـ Logout عشان ما تنتقل نسبة البطارية لحساب جديد
  void resetState() {
    _percent = -1;
    _isCharging = false;
    _lastUpdated = null;
    _lastUploadAt = DateTime.fromMillisecondsSinceEpoch(0);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _parser.dispose();
    super.dispose();
  }
}
