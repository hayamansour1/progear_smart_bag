import 'package:shared_preferences/shared_preferences.dart';

class ActivitySeenStore {
  ActivitySeenStore._();
  static final ActivitySeenStore instance = ActivitySeenStore._();

  SharedPreferences? _prefs;

  /// Call once on app startup 
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> _sp() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ---------- Keys ----------
  String _kUnread(String cid) => 'act.$cid.unread';
  String _kLastAll(String cid) => 'act.$cid.last_all';
  String _kLastW(String cid) => 'act.$cid.last_weight';
  String _kLastN(String cid) => 'act.$cid.last_notes';

  // ---------- Unread flag (header dot) ----------
  Future<bool> hasUnread(String controllerId) async {
    final p = await _sp();
    return p.getBool(_kUnread(controllerId)) ?? false;
  }

  /// Set unread=true (show dot).
  Future<void> bumpUnread(String controllerId) async {
    final p = await _sp();
    await p.setBool(_kUnread(controllerId), true);
  }

  /// Set unread=false (hide dot).
  Future<void> clearUnread(String controllerId) async {
    final p = await _sp();
    await p.setBool(_kUnread(controllerId), false);
  }

  // ---------- Last seen getters ----------
  Future<DateTime?> lastSeenAll(String controllerId) async {
    final p = await _sp();
    final ms = p.getInt(_kLastAll(controllerId));
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<DateTime?> lastSeenWeight(String controllerId) async {
    final p = await _sp();
    final ms = p.getInt(_kLastW(controllerId));
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<DateTime?> lastSeenNotes(String controllerId) async {
    final p = await _sp();
    final ms = p.getInt(_kLastN(controllerId));
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // ---------- Mark seen (called from ActivityPage when tabs are selected) ----------
  Future<void> markSeenAll(String controllerId) async {
    final p = await _sp();
    await p.setInt(_kLastAll(controllerId), DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> markSeenWeight(String controllerId) async {
    final p = await _sp();
    await p.setInt(_kLastW(controllerId), DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> markSeenNotes(String controllerId) async {
    final p = await _sp();
    await p.setInt(_kLastN(controllerId), DateTime.now().millisecondsSinceEpoch);
  }
}
