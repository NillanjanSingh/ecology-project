import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentity {
  static const String _key = 'ecology_device_id';

  /// Retrieves the existing device ID or generates and saves a new one.
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_key);
    
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }
    
    return id;
  }
}
