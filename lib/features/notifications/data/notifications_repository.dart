import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:progear_smart_bag/features/notifications/domain/models/notification_event.dart';

class NotificationsRepository {
  final SupabaseClient sb;
  NotificationsRepository(this.sb);

  Future<void> insert({
    required String controllerID,
    required String userID,     // auth.currentUser!.id
    required String kind,
    required String title,
    required String message,
    String severity = 'info',
    Map<String, dynamic>? meta,
  }) async {
    await sb.rpc('insert_notification', params: {
      'p_controller': controllerID,
      'p_user': userID,
      'p_kind': kind,
      'p_title': title,
      'p_message': message,
      'p_severity': severity,
      'p_meta': meta,
    });
  }

  Future<List<NotificationEvent>> fetch({
    required String controllerID,
    int limit = 50,
    int offset = 0,
  }) async {
    final List rows = await sb.rpc('fetch_notifications', params: {
      'p_controller': controllerID,
      'p_limit': limit,
      'p_offset': offset,
    });
    return rows
        .map((e) => NotificationEvent.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
