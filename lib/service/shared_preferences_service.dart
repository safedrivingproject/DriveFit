import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static late final SharedPreferences _instance;

  static Future<SharedPreferences> init() async =>
      _instance = await SharedPreferences.getInstance();

  static bool getBool(String key, bool defaultValue) =>
      _instance.getBool(key) ?? defaultValue;

  static Future<bool> setBool(String key, bool value) async =>
      _instance.setBool(key, value);

  static int getInt(String key, int defaultValue) =>
      _instance.getInt(key) ?? defaultValue;

  static Future<bool> setInt(String key, int value) async =>
      _instance.setInt(key, value);

  static double getDouble(String key, double defaultValue) =>
      _instance.getDouble(key) ?? defaultValue;

  static Future<bool> setDouble(String key, double value) async =>
      _instance.setDouble(key, value);

  static List<String> getStringList(String key, List<String> defaultValue) =>
      _instance.getStringList(key) ?? defaultValue;

  static Future<bool> setStringList(String key, List<String> value) async =>
      _instance.setStringList(key, value);

  static Future<bool> clear() async => _instance.clear();
}
