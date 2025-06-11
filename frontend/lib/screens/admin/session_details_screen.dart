import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../template/details_screen.dart';
import '../trainer/trainer_details_screen.dart';

class SessionDetailsScreen extends StatelessWidget {
  final int sessionId;

  SessionDetailsScreen({required this.sessionId});

  // Function to fetch session details
  Future<Map<String, dynamic>> fetchSessionDetails(int sessionId) async {
    try {
      final session = await ApiService.getSessionById(sessionId);
      final trainerData = await ApiService.getTrainers();
      final counts = await ApiService.getSessionParticipantCounts(sessionId);

      return {'session': session, 'trainers': trainerData, 'counts': counts};
    } catch (e) {
      throw Exception('Failed to load session details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailScreenTemplate(
      screenTitle: 'Session Details',
      fetchData: fetchSessionDetails,
      dynamicTitleKey: 'title',
      itemId: sessionId,
      titleAtTop:
          'Session Overview', // Default value, will be overwritten by API data
      detailItems: [
        DetailItem(
          title: 'Workshop Title',
          icon: '0xe668',
          subtitle: (data) => data['session']['workshop']['title'] ?? 'N/A',
        ),
        DetailItem(
          title: 'Workshop Description',
          icon: '0xf580',
          subtitle:
              (data) =>
                  data['session']['workshop']['description'] ??
                  'No description available',
        ),
        DetailItem(
          title: 'Location',
          icon: '0xe3ab', // Location Icon
          subtitle: (data) => data['session']['location'] ?? 'Location unknown',
        ),
        DetailItem(
          title: 'Date',
          icon: '0xf692', // Date Icon
          subtitle: (data) {
            final date = data['session']['date_time'];
            return date != null ? formatDate(date) : 'N/A';
          },
        ),
        DetailItem(
          title: 'Time',
          icon: '0xe03a', // Time Icon
          subtitle: (data) {
            final time = data['session']['date_time'];
            return time != null ? formatTime(time) : 'N/A';
          },
        ),
        DetailItem(
          title: 'Registration Deadline',
          icon: '0xe667', // Deadline Icon
          subtitle: (data) {
            final deadline = data['session']['registration_deadline'];
            return deadline != null ? formatDate(deadline) : 'N/A';
          },
        ),
        DetailItem(
          title: 'Target Audience',
          icon: '0xe9e9', // Target Audience Icon
          subtitle:
              (data) =>
                  data['session']['target_audience'] ??
                  'No target audience specified',
        ),
      ],
      sections: [
        Section(
          title: 'Registered Participants',
          builder: (data) {
            final participants =
                data['counts']['registered_participants'] ?? [];
            return buildParticipantList('Registered', participants);
          },
        ),
        Section(
          title: 'Attended Participants',
          builder: (data) {
            final participants = data['counts']['attended_participants'] ?? [];
            return buildParticipantList('Attended', participants);
          },
        ),
        Section(
          title: 'Assigned Trainers',
          builder: (data) {
            final trainers = data['session']['trainers'] ?? [];
            return buildTrainerList(context, trainers);
          },
        ),
      ],
    );
  }

  // Helper method to format the date
  String formatDate(String dateTime) {
    final dt = DateTime.tryParse(dateTime);
    return dt != null ? DateFormat('yyyy-MM-dd').format(dt) : dateTime;
  }

  // Helper method to format the time
  String formatTime(String dateTime) {
    final dt = DateTime.tryParse(dateTime);
    return dt != null ? DateFormat('h:mm a').format(dt) : '';
  }

  // Helper method to build the participant list
  Widget buildParticipantList(String label, List participants) {
    return ExpansionTile(
      title: Text(
        '$label - Count: ${participants.length}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey.shade700,
        ),
      ),
      children:
          participants.map<Widget>((participant) {
            return ListTile(title: Text(participant['name']));
          }).toList(),
    );
  }

  // Helper method to build the trainer list
  Widget buildTrainerList(BuildContext context, List trainers) {
    return Column(
      children:
          trainers.map<Widget>((trainer) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              color: Colors.white,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                title: Text(trainer['name']),
                onTap: () {
                  if (trainer['id'] != null) {
                    Navigator.push(
                      // Use context from the builder method
                      // ignore: use_build_context_synchronously
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                TrainerDetailsScreen(trainerId: trainer['id']),
                      ),
                    );
                  }
                },
              ),
            );
          }).toList(),
    );
  }
}
