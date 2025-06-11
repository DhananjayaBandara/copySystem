import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalyticsApiService {
  static const String baseUrl = 'http://localhost:8000/api/api/analytics';

  static Future<Map<String, dynamic>> getSessionsAnalytics() async {
    final response = await http.get(Uri.parse('$baseUrl/sessions/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load sessions analytics');
    }
  }

  static Future<Map<String, dynamic>> getWorkshopsAnalytics() async {
    final response = await http.get(Uri.parse('$baseUrl/workshops/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load workshops analytics');
    }
  }

  static Future<Map<String, dynamic>> getTrainersAnalytics() async {
    final response = await http.get(Uri.parse('$baseUrl/trainers/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load trainers analytics');
    }
  }

  static Future<Map<String, dynamic>> getTrainerDetailAnalytics(
    int trainerId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trainers/$trainerId/detail/'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load trainer detail analytics');
    }
  }

  static Future<Map<String, dynamic>> getParticipantsAnalytics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/participants/overview/'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load participants analytics');
    }
  }

  static Future<Map<String, dynamic>> getWorkshopsOverview() async {
    final response = await http.get(Uri.parse('$baseUrl/workshops/overview/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load workshops overview');
    }
  }

  static Future<List<dynamic>> getWorkshopsList() async {
    final response = await http.get(Uri.parse('$baseUrl/workshops/list/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Uncomment below for temporary fallback
      // return [];
      throw Exception('Failed to load workshops list');
    }
  }

  static Future<Map<String, dynamic>> getWorkshopDetail(int workshopId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workshops/$workshopId/detail/'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {}
    throw Exception('Failed to load workshop detail');
  }

  static Future<Map<String, dynamic>> getSessionsOverview() async {
    final response = await http.get(Uri.parse('$baseUrl/sessions/overview/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load sessions overview');
    }
  }

  static Future<List<dynamic>> getSessionsList() async {
    final response = await http.get(Uri.parse('$baseUrl/sessions/list/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load sessions list');
    }
  }

  static Future<Map<String, dynamic>> getSessionDetail(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/$sessionId/detail/'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load session detail');
    }
  }
}
