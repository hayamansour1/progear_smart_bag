import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:progear_smart_bag/features/notifications/domain/models/notification_event.dart';

class NotificationsRepository {
  final SupabaseClient _client;
  NotificationsRepository(this._client);

  Future<List<NotificationEvent>> fetch({
    required String controllerID,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _client.rpc('fetch_notifications', params: {
      'p_controller': controllerID,
      'p_limit': limit,
      'p_offset': offset,
    });

    final list = (res as List<dynamic>?) ?? [];

    return list.map((row) {
      final m = row as Map<String, dynamic>;
      return NotificationEvent(
        id: m['notificationid'] as String,
        controllerID: m['controllerid'] as String,
        userID: m['userid'] as String?,
        kind: m['kind'] as String,
        title: m['title'] as String,
        message: m['message'] as String,
        severity: m['severity'] as String,
        meta: m['meta'] as Map<String, dynamic>?,
        time: DateTime.parse(m['timestamp'] as String),
      );
    }).toList();
  }
}
