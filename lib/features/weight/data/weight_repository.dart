import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:progear_smart_bag/features/weight/domain/models/weight_entry.dart';

/// WeightRepository
/// Fetches bag weight readings (in grams) from Supabase.
class WeightRepository {
  final SupabaseClient sb;
  WeightRepository(this.sb);

  Future<List<WeightEntry>> fetchHistory({
    required String controllerID,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await sb.rpc('fetch_weight_history', params: {
      'p_controller': controllerID,
      'p_limit': limit,
      'p_offset': offset,
    });

    if (res is! List) return const [];

    return res
        .whereType<Map<String, dynamic>>()
        .map(WeightEntry.fromMap)
        .toList();
  }
}
