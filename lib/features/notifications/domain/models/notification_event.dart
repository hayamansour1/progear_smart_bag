class NotificationEvent {
  final String id;            // notificationID (text)
  final String controllerID;
  final String? userID;       // optional if 
  final String kind;          // 'weight_reset', 'underweight', ...
  final String title;
  final String message;
  final String severity;      // 'info' | 'warn' | 'error' | 'success'
  final Map<String, dynamic>? meta;
  final DateTime time;

  NotificationEvent({
    required this.id,
    required this.controllerID,
    required this.userID,
    required this.kind,
    required this.title,
    required this.message,
    required this.severity,
    required this.meta,
    required this.time,
  });

  factory NotificationEvent.fromMap(Map<String, dynamic> m) {
    return NotificationEvent(
      id: m['notificationid'] as String? ?? m['notificationID'] as String,
      controllerID: m['controllerid'] as String? ?? m['controllerID'] as String,
      userID: (m['userid'] ?? m['userID']) as String?,
      kind: m['kind'] as String? ?? 'generic',
      title: m['title'] as String? ?? 'Notification',
      message: m['message'] as String? ?? '',
      severity: m['severity'] as String? ?? 'info',
      meta: m['meta'] as Map<String, dynamic>?,
      time: DateTime.parse(m['timestamp'] as String),
    );
  }
}
