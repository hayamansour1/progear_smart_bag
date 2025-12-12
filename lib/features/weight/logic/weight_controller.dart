// lib/features/weight/logic/weight_controller.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';
import 'package:progear_smart_bag/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:progear_smart_bag/core/services/parser/bag_parser.dart';
import 'package:progear_smart_bag/features/activity/data/activity_seen_store.dart';
import 'package:progear_smart_bag/core/debug/debug_flags.dart';

/// WeightController
class WeightController extends ChangeNotifier {
  final Logger _log = logger(WeightController);
  final BagParser _parser;

  WeightController(this._parser);

  // --- State (grams) ---
  double _currentG = 0;
  double _expectedG = 0;
  double _deltaG = 0;

  double get currentG => _currentG;
  double get expectedG => _expectedG;
  double get deltaG => _deltaG;

  // --- Config thresholds ---
  static const double _deltaThreshold = 200.0;
  static const Duration _notifyCooldown = Duration(seconds: 60);
  DateTime _lastDeltaNotifyAt = DateTime.fromMillisecondsSinceEpoch(0);

  StreamSubscription<String>? _sub;

  void resetForNewOwner() {
    _currentG = 0;
    _expectedG = 0;
    _deltaG = 0;
    _lastDeltaNotifyAt = DateTime.fromMillisecondsSinceEpoch(0);
    notifyListeners();
  }

  Future<void> boot({required String controllerID}) async {
    _log.t('boot(): controllerID = $controllerID');
    await loadSnapshotFromDb(controllerID);
  }

  Future<void> loadSnapshotFromDb(String controllerID) async {
    try {
      final sb = Supabase.instance.client;

      final row = await sb
          .from('esp32_controller')
          .select('expectedWeight, currentWeight')
          .eq('controllerID', controllerID)
          .maybeSingle();

      if (row == null) {
        _log.w('loadSnapshotFromDb: no controller row for $controllerID');
        _currentG = 0;
        _expectedG = 0;
        _deltaG = 0;
        notifyListeners();
        return;
      }

      final exp = (row['expectedWeight'] as num?)?.toDouble() ?? 0.0;
      final cur = (row['currentWeight'] as num?)?.toDouble() ?? 0.0;

      _expectedG = exp;
      _currentG = cur;
      _deltaG = _currentG - _expectedG;

      _log.i(
        'loadSnapshotFromDb: expected=$exp, current=$cur, delta=$_deltaG',
      );
      notifyListeners();
    } catch (e) {
      _log.e('loadSnapshotFromDb failed: $e');
    }
  }

  Future<void> bindToCharacteristic(
    BluetoothCharacteristic ch, {
    required String controllerID,
  }) async {
    await _parser.bind(ch);
    await _sub?.cancel();

    _sub = _parser.stream.listen(
      (data) => _onLine(data, controllerID: controllerID),
      onError: (e) {
        _log.e('WeightController stream error: $e');
      },
    );
  }

  Future<void> unbind() async {
    await _sub?.cancel();
    _sub = null;
    await _parser.unbind();
  }

  void applyExpectedFromReset(double expectedG) {
    _expectedG = expectedG;
    _deltaG = _currentG - _expectedG;
    notifyListeners();
  }

  // ------------------------------ PARSING ------------------------------

  void _onLine(String raw, {required String controllerID}) {
    DebugFlags.logWeight('WeightController raw: $raw');

    var t = raw.trim();
    if (t.isEmpty) return;

    double? w;

    final colonIdx = t.indexOf(':');
    if (colonIdx != -1 && colonIdx < t.length - 1) {
      final payload = t.substring(colonIdx + 1).trim();
      if (payload.isNotEmpty) {
        t = payload;
      }
    }

    // JSON: {"g":1234} or {"weight":1234}
    if (t.startsWith('{') && t.endsWith('}')) {
      try {
        final m = jsonDecode(t) as Map<String, dynamic>;
        w = _readDouble(m['g'] ?? m['w'] ?? m['weight']);
        DebugFlags.logWeight('parsed JSON weight: $w');
      } catch (e) {
        _log.e('JSON parse error in WeightController: $e');
      }
    }

    // Text fallback: W:1234 or WEIGHT=1234
    w ??= _extractDouble(
      t,
      RegExp(
        r'(?:W|WEIGHT|WEIGHT_DATA)\s*[:=]\s*([-+]?\d+(?:\.\d+)?)',
        caseSensitive: false,
      ),
    );

    DebugFlags.logWeight('weight after parsing: $w');

    if (w != null) {
      _applyReading(currentG: w, controllerID: controllerID);
    }
  }

  double? _readDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  double? _extractDouble(String src, RegExp re) {
    final m = re.firstMatch(src);
    return m == null ? null : double.tryParse(m.group(1)!);
  }

  // --------------------------- APPLY & NOTIFY --------------------------

  Future<void> _applyReading({
    required double currentG,
    required String controllerID,
  }) async {
    final sb = Supabase.instance.client;

    final bool noBaseline = _expectedG <= 0;

    _currentG = currentG;

    if (noBaseline) {
      _deltaG = 0;

      _log.t(
        'no baseline yet for controller=$controllerID -> current=$_currentG, expected=$_expectedG',
      );

      notifyListeners();

      try {
        await sb.rpc('insert_weight_reading', params: {
          'p_sensor': 'hx711',
          'p_weight': _currentG,
          'p_controller': controllerID,
        });
      } catch (e) {
        _log.e('insert_weight_reading(noBaseline) failed: $e');
      }

      return;
    }

    final prevDelta = _deltaG;

    _deltaG = _currentG - _expectedG;

    _log.t(
      '(_applyReading) controllerID=$controllerID, '
      'currentG=$_currentG, expected=$_expectedG, deltaG=$_deltaG',
    );

    notifyListeners();

    try {
      await sb.rpc('insert_weight_reading', params: {
        'p_sensor': 'hx711',
        'p_weight': _currentG,
        'p_controller': controllerID,
      });

      await sb
          .from('esp32_controller')
          .update({'currentWeight': _currentG})
          .eq('controllerID', controllerID);
    } catch (e) {
      _log.e('insert_weight_reading / update currentWeight failed: $e');
    }

    final now = DateTime.now();
    final over = _deltaG >= _deltaThreshold;
    final under = _deltaG <= -_deltaThreshold;
    final beyond = over || under;

    if (!beyond) return;
    if (now.difference(_lastDeltaNotifyAt) < _notifyCooldown) return;

    if ((prevDelta >= _deltaThreshold && over) ||
        (prevDelta <= -_deltaThreshold && under)) {
      return;
    }

    _lastDeltaNotifyAt = now;

    final uid = sb.auth.currentUser?.id;

    if (uid != null) {
      final severity = 'warn';
      final title = over ? 'Overweight detected' : 'Underweight detected';
      final msg = over
          ? 'Bag is heavier than expected by ${_deltaG.toStringAsFixed(1)} g.'
          : 'Bag is lighter than expected by ${_deltaG.abs().toStringAsFixed(1)} g.';

      try {
        await sb.rpc('insert_notification', params: {
          'p_controller': controllerID,
          'p_user': uid,
          'p_kind': 'weight_delta',
          'p_title': title,
          'p_message': msg,
          'p_severity': severity,
          'p_meta': {
            'current_g': _currentG,
            'expected_g': _expectedG,
            'delta_g': _deltaG,
            'threshold_g': _deltaThreshold,
          },
        });

        await ActivitySeenStore.instance.bumpUnread(controllerID);
      } catch (e) {
        _log.e('insert_notification(weight_delta) failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _parser.dispose();
    super.dispose();
  }
}
