import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';
import 'package:progear_smart_bag/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:progear_smart_bag/core/services/parser/bag_parser.dart';
import 'package:progear_smart_bag/features/activity/data/activity_seen_store.dart';

/// WeightController
/// Handles live weight readings from BLE, computes delta vs expected,
/// uploads status to DB if needed, and records notifications when threshold exceeded.
class WeightController extends ChangeNotifier {
  final Logger _log = logger(WeightController);
  final BagParser _parser;

  WeightController(this._parser);

  // --- State (in grams)
  double _currentG = 0;
  double _expectedG = 0;
  double _deltaG = 0;

  double get currentG => _currentG;
  double get expectedG => _expectedG;
  double get deltaG => _deltaG;

  // --- Config thresholds
  static const double _deltaThreshold = 200.0; // ±200 g tolerance
  static const Duration _notifyCooldown = Duration(seconds: 60); // avoid spam
  DateTime _lastDeltaNotifyAt = DateTime.fromMillisecondsSinceEpoch(0);

  StreamSubscription<String>? _sub;

  /// Boot: load expectedWeight once from DB so UI has baseline before BLE data starts.
  Future<void> boot({required String controllerID}) async {
    try {
      _log.t('Get Form DB ,controllerID : $controllerID');
      final row = await Supabase.instance.client
          .from('esp32_controller')
          .select('expectedWeight')
          .eq('controllerID', controllerID)
          .maybeSingle();

      final exp = (row?['expectedWeight'] as num?)?.toDouble() ?? 0.0;
      _expectedG = exp;
      _deltaG = _currentG - _expectedG;
      _log.i('expectedWeight: $exp, currentG: $_currentG, deltaG: $_deltaG');
      notifyListeners();
    } catch (e) {
      _log.e('WeightController boot() failed: $e');
    }
  }

  /// Bind BLE notify characteristic to BagParser
  Future<void> bindToCharacteristic(BluetoothCharacteristic ch,
      {required String controllerID}) async {
    // read data from BLE
    await _parser.bind(ch);
    await _sub?.cancel();
    // listen to data
    _sub = _parser.stream.listen(
        (data) => _onLine(data, controllerID: controllerID), onError: (e) {
      _log.e('WeightController stream error: $e');
    });
  }

  /// Unbind BLE stream and release resources
  Future<void> unbind() async {
    await _sub?.cancel();
    _sub = null;
    await _parser.unbind();
  }

  /// Called from ResetWeightSheet to update expected value locally after successful reset
  void applyExpectedFromReset(double expectedG) {
    _expectedG = expectedG;
    _deltaG = _currentG - _expectedG;
    notifyListeners();
  }

  // ------------------------------ PARSING ------------------------------

  void _onLine(String raw, {required String controllerID}) {
    _log.i('WeightController: $raw');
    final t = raw.trim();
    if (t.isEmpty) return;

    double? w;

    // JSON format: {"w": 6234} or {"weight": 6234}
    if (t.startsWith('{') && t.endsWith('}')) {
      try {
        final m = jsonDecode(t) as Map<String, dynamic>;
        w = _readDouble(m['w'] ?? m['weight']);
        _log.i('read wight form JSON: $w');
      } catch (_) {}
    }

    // Text format: W:6234 or WEIGHT=6234
    w ??= _extractDouble(
      t,
      RegExp(r'(?:W|WEIGHT)\s*[:=]\s*([-+]?\d+(?:\.\d+)?)',
          caseSensitive: false),
    );

    _log.i('wight after formatting: $w');

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

  Future<void> _applyReading(
      {required double currentG, required String controllerID}) async {
    final prevDelta = _deltaG;

    _currentG = currentG;
    _deltaG = _currentG - _expectedG;

    _log.t(
        '(_ApplyReading) controllerID: $controllerID, currentG: $_currentG, deltaG: $_deltaG');

    notifyListeners(); // update UI

    // Check threshold + cooldown
    final now = DateTime.now();
    final over = _deltaG >= _deltaThreshold;
    final under = _deltaG <= -_deltaThreshold;
    final beyond = over || under;

    if (!beyond) return;
    if (now.difference(_lastDeltaNotifyAt) < _notifyCooldown) return;

    // Skip repeating same-direction alerts
    if ((prevDelta >= _deltaThreshold && over) ||
        (prevDelta <= -_deltaThreshold && under)) {
      return;
    }

    _lastDeltaNotifyAt = now;

    // Record notification
    final sb = Supabase.instance.client;
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

        // ✅ Mark unread so the blue dot shows up immediately
        await ActivitySeenStore.instance.bumpUnread(controllerID);

        // TODO (Phase 3): push via Edge Function (FCM)
      } catch (e) {
        _log.e('insert_notification(weight_delta) failed: $e');
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _parser.dispose();
    super.dispose();
  }
}
