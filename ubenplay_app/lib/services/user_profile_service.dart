import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';

/// Servicio para guardar/cargar perfil del usuario
class UserProfileService {
  static const _key = 'user_profile';

  static Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        return UserProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
      } catch (_) {
        return const UserProfile();
      }
    }
    return const UserProfile();
  }

  static Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  static Future<bool> getDifficulty() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('difficulty_normal') ?? false;
  }

  static Future<void> setDifficulty(bool normal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('difficulty_normal', normal);
  }
}
