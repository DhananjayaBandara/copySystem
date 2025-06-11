import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<List<dynamic>> getSessions() async {
    final response = await http.get(Uri.parse('$baseUrl/sessions/'));
    if (response.statusCode == 200) {
      final sessions = jsonDecode(response.body);
      // Ensure token field is present in each session
      for (var session in sessions) {
        if (!session.containsKey('token') || session['token'] == null) {
          throw Exception('Session token is missing in the response.');
        }
      }
      return sessions;
    } else {
      throw Exception('Failed to load sessions');
    }
  }

  static Future<Map<String, dynamic>> getSessionById(int sessionId) async {
    final response = await http.get(Uri.parse('$baseUrl/sessions/'));
    if (response.statusCode == 200) {
      final sessions = jsonDecode(response.body) as List;
      return sessions.firstWhere((s) => s['id'] == sessionId);
    } else {
      throw Exception('Failed to load session');
    }
  }

  static Future<bool> createSession(Map<String, dynamic> sessionData) async {
    try {
      // Ensure date_time and registration_deadline are in ISO 8601 format
      if (sessionData.containsKey('date_time')) {
        sessionData['date_time'] =
            DateTime.parse(sessionData['date_time']).toIso8601String();
      }
      if (sessionData.containsKey('registration_deadline')) {
        sessionData['registration_deadline'] =
            DateTime.parse(
              sessionData['registration_deadline'],
            ).toIso8601String();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/sessions/create/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sessionData),
      );
      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to create session: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error creating session: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getSessionsByWorkshopId(int workshopId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/workshop/$workshopId/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load sessions for workshop');
    }
  }

  static Future<List<String>> getEmailsBySession(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/$sessionId/emails/'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['emails']);
    } else {
      throw Exception('Failed to load emails');
    }
  }

  static Future<List<String>> getAllParticipantEmails() async {
    final response = await http.get(Uri.parse('$baseUrl/participants/emails/'));
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load participant emails');
    }
  }

  static Future<bool> updateSession(
    int sessionId,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      // Ensure date_time and registration_deadline are in ISO 8601 format
      if (sessionData.containsKey('date_time')) {
        sessionData['date_time'] =
            DateTime.parse(sessionData['date_time']).toIso8601String();
      }
      if (sessionData.containsKey('registration_deadline')) {
        sessionData['registration_deadline'] =
            DateTime.parse(
              sessionData['registration_deadline'],
            ).toIso8601String();
      }

      final response = await http.put(
        Uri.parse('$baseUrl/sessions/update/$sessionId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sessionData),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update session: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating session: $e');
      return false;
    }
  }

  static Future<bool> deleteSession(int sessionId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/sessions/delete/$sessionId/'),
    );
    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getParticipantTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/participant-types/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load participant types');
    }
  }

  static Future<bool> deleteParticipantType(int typeId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/participant-types/delete/$typeId/'),
    );
    return response.statusCode == 200;
  }

  static Future<bool> createParticipantType(
    Map<String, dynamic> participantTypeData,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/participant-types/create/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(participantTypeData),
    );
    return response.statusCode == 201;
  }

  static Future<bool> updateParticipantType(
    int typeId,
    Map<String, dynamic> participantTypeData,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/participant-types/update/$typeId/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(participantTypeData),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getRequiredFieldsForType(
    int typeId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/participant-types/$typeId/required-fields/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load required fields');
    }
  }

  static Future<int?> registerParticipant(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/participants/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)['id'];
    } else {
      throw jsonDecode(response.body);
    }
  }

  static Future<List<dynamic>> getParticipants() async {
    final response = await http.get(Uri.parse('$baseUrl/participants/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load participants');
    }
  }

  static Future<bool> deleteParticipant(int participantId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/participants/delete/$participantId/'),
    );
    return response.statusCode == 200;
  }

  static Future<bool> registerForSessionWithParticipant(
    int sessionId,
    int participantId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registrations/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'participant_id': participantId,
        'session_id': sessionId,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<Map<String, int>> getAdminDashboardCounts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin-dashboard/counts/'),
    );
    if (response.statusCode == 200) {
      return Map<String, int>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load counts');
    }
  }

  static Future<List<dynamic>> getTrainers() async {
    final response = await http.get(Uri.parse('$baseUrl/trainers/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load trainers');
    }
  }

  static Future<bool> deleteTrainer(int trainerId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/trainers/delete/$trainerId/'),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getTrainerDetails(int trainerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trainers/$trainerId/details/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load trainer details');
    }
  }

  static Future<bool> createTrainer(Map<String, dynamic> trainerData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trainers/create/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(trainerData),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      throw jsonDecode(response.body);
    }
  }

  static Future<bool> updateTrainer(
    int trainerId,
    Map<String, dynamic> trainerData,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/trainers/update/$trainerId/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(trainerData),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      throw jsonDecode(response.body);
    }
  }

  static Future<List<dynamic>> getWorkshops() async {
    final response = await http.get(Uri.parse('$baseUrl/workshops/'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load workshops');
    }
  }

  static Future<bool> createWorkshop(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/workshops/create/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  static Future<bool> deleteWorkshop(int workshopId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/workshops/delete/$workshopId/'),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getWorkshopDetails(int workshopId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workshops/$workshopId/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load workshop details');
    }
  }

  static Future<bool> updateWorkshop(
    int workshopId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/workshops/update/$workshopId/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  static Future<bool> assignTrainersToSession(
    int sessionId,
    List<int> trainerIds,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trainers/sessions/assign/'), // Corrected URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_id': sessionId, 'trainer_ids': trainerIds}),
      );
      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to assign trainers: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error assigning trainers: $e');
      return false;
    }
  }

  static Future<bool> removeTrainerFromSession(
    int sessionId,
    int trainerId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/trainers/sessions/remove/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_id': sessionId, 'trainer_id': trainerId}),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to remove trainer: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error removing trainer: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getParticipantByNIC(String nic) async {
    final response = await http.get(
      Uri.parse('$baseUrl/participants/nic/$nic/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to fetch participant details');
    }
  }

  static Future<bool> markAttendance(String token, String nic) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$token/attendance/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nic': nic}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> createFeedbackQuestion(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/feedback/questions/create/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  static Future<List<dynamic>> getFeedbackQuestions(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/feedback/questions/$sessionId/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load feedback questions');
    }
  }

  static Future<bool> submitFeedbackResponse(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/feedback/responses/submit/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  static Future<List<dynamic>> getFeedbackResponses(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/feedback/responses/$sessionId/'),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // Ensure the response is a List, otherwise return an empty list
      if (body is List) {
        return body;
      } else {
        return [];
      }
    } else {
      // Return empty list on error to avoid exceptions in UI
      return [];
    }
  }

  static Future<Map<String, dynamic>> getSessionParticipantCounts(
    int sessionId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/$sessionId/participants/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load participant counts');
    }
  }

  static Future<Map<String, dynamic>> getParticipantSessionsInfo(
    int participantId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/participants/$participantId/sessions/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load participant sessions info');
    }
  }

  static Future<Map<String, dynamic>> getSessionDashboard(int sessionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/$sessionId/dashboard/'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load session dashboard');
    }
  }

  static Future<Map<String, dynamic>> getParticipantById(
    int participantId,
  ) async {
    final response = await http.get(Uri.parse('$baseUrl/participants/'));
    if (response.statusCode == 200) {
      final participants = jsonDecode(response.body) as List;
      return participants.firstWhere((p) => p['id'] == participantId);
    } else {
      throw Exception('Failed to load participant details');
    }
  }
}
