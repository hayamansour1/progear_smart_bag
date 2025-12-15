// lib/features/weight/domain/models/weight_entry.dart
class WeightEntry {
  final DateTime time;
  final double currentG;           // grams
  final double expectedSnapshotG;  // grams
  final double deltaG;             // grams (current - expected)

  const WeightEntry({
    required this.time,
    required this.currentG,
    required this.expectedSnapshotG,
    required this.deltaG,
  });

  factory WeightEntry.fromMap(Map<String, dynamic> m) {
    // RPC returns: inserted_at, current_g, expected_g, delta_g
    final inserted = m['inserted_at'] as String;
    final cur = (m['current_g'] as num?)?.toDouble() ?? 0.0;
    final exp = (m['expected_g'] as num?)?.toDouble() ?? 0.0;
    final dlt = (m['delta_g'] as num?)?.toDouble() ?? (cur - exp);

    return WeightEntry(
      time: DateTime.parse(inserted),
      currentG: cur,
      expectedSnapshotG: exp,
      deltaG: dlt,
    );
  }
}
