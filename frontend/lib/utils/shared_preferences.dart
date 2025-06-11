import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHelper {
  static Future<void> saveParticipantInfo({
    required String name,
    required String email,
    required String contactNumber,
    required String nic,
    required String dob,
    required String district,
    required String gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('contactNumber', contactNumber);
    await prefs.setString('nic', nic);
    await prefs.setString('dob', dob);
    await prefs.setString('district', district);
    await prefs.setString('gender', gender);
  }

  static Future<Map<String, String>> loadParticipantInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('name') ?? '',
      'email': prefs.getString('email') ?? '',
      'contactNumber': prefs.getString('contactNumber') ?? '',
      'nic': prefs.getString('nic') ?? '',
      'dob': prefs.getString('dob') ?? '',
      'district': prefs.getString('district') ?? '',
      'gender': prefs.getString('gender') ?? 'Male',
    };
  }

  static Future<void> clearParticipantInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('contactNumber');
    await prefs.remove('nic');
    await prefs.remove('dob');
    await prefs.remove('district');
    await prefs.remove('gender');
  }
}
