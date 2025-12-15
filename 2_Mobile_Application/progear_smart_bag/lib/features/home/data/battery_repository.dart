import 'package:supabase_flutter/supabase_flutter.dart';

/// BatteryRepository
/// Single place to read/write battery status via RPCs.
class BatteryRepository {
  BatteryRepository(this._sb);
  final SupabaseClient _sb;

  /// push current battery status to DB (RPC)
  Future<void> setStatus({
    required String controllerID,
    required int percent,   // 0..100
    required bool charging,
  }) async {
    await _sb.rpc('set_battery_status', params: {
      'p_controller': controllerID,
      'p_percent': percent,
      'p_charging': charging,
    });
  }

  /// fetch last known battery status from DB (RPC)
  Future<({int percent, bool charging, DateTime updatedAt})?> getStatus({
    required String controllerID,
  }) async {
    final res = await _sb.rpc('get_battery_status', params: {
      'p_controller': controllerID,
    });
    if (res is List && res.isNotEmpty) {
      final m = res.first as Map<String, dynamic>;
      return (
        percent: (m['battery_percent'] as int?) ?? 0,
        charging: (m['is_charging'] as bool?) ?? false,
        updatedAt: DateTime.parse(m['battery_updated_at'] as String),
      );
    }
    return null;
  }
}
