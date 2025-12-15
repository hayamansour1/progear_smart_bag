import 'package:shared_preferences/shared_preferences.dart';

class LastControllerStore {
  LastControllerStore._();
  static final LastControllerStore instance = LastControllerStore._();

  static const _keyLastControllerID = 'last_controller_id';

  Future<void> setLastControllerID(String controllerID) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastControllerID, controllerID);
  }

  Future<String?> getLastControllerID() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_keyLastControllerID);
    if (v == null || v.isEmpty) return null;
    return v;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastControllerID);
  }
}
