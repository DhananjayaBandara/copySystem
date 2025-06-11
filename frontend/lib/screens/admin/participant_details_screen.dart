import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/app_footer.dart';

class ParticipantDetailsScreen extends StatefulWidget {
  final dynamic participant; // can be Map or int (id)

  ParticipantDetailsScreen({required this.participant});

  @override
  State<ParticipantDetailsScreen> createState() =>
      _ParticipantDetailsScreenState();
}

class _ParticipantDetailsScreenState extends State<ParticipantDetailsScreen> {
  late Future<Map<String, dynamic>> _participantFuture;

  @override
  void initState() {
    super.initState();
    if (widget.participant is int) {
      _participantFuture = ApiService.getParticipantById(widget.participant);
    } else if (widget.participant is Map && widget.participant['id'] != null) {
      _participantFuture = ApiService.getParticipantById(
        widget.participant['id'],
      );
    } else {
      _participantFuture = Future.value(
        widget.participant as Map<String, dynamic>,
      );
    }
  }

  Future<Map<String, dynamic>> fetchSessionsInfo(int participantId) async {
    return await ApiService.getParticipantSessionsInfo(participantId);
  }

  Widget buildDetailTile(IconData icon, String title, String? value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(value ?? 'N/A'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: _participantFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Participant Details');
            }
            final participant = snapshot.data ?? {};
            return Text('${participant['name'] ?? 'Participant Details'}');
          },
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _participantFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Failed to load participant details.'));
          }
          final participant = snapshot.data!;
          final properties =
              participant['properties'] as Map<String, dynamic>? ?? {};

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${participant['name'] ?? 'Unnamed Participant'}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          SizedBox(height: 10),
                          Divider(),
                          buildDetailTile(
                            Icons.badge_outlined,
                            'Name',
                            participant['name'].toString(),
                          ),
                          buildDetailTile(
                            Icons.email_outlined,
                            'Email',
                            participant['email'],
                          ),
                          buildDetailTile(
                            Icons.phone_android_outlined,
                            'Contact Number',
                            participant['contact_number'],
                          ),
                          buildDetailTile(
                            Icons.card_membership,
                            'NIC',
                            participant['nic'],
                          ),
                          buildDetailTile(
                            Icons.calendar_today_outlined,
                            'Date of Birth',
                            participant['dob'],
                          ),
                          buildDetailTile(
                            Icons.location_on_outlined,
                            'District',
                            participant['district'],
                          ),
                          buildDetailTile(
                            Icons.person,
                            'Gender',
                            participant['gender'],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Participant Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        '${participant['participant_type']?['name'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  properties.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'No details available.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                      : Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children:
                                properties.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            entry.key,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade800,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(entry.value.toString()),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                  SizedBox(height: 20),
                  Text(
                    'Sessions Registered',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: fetchSessionsInfo(participant['id']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Error loading registrations',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (!snapshot.hasData ||
                          (snapshot.data!['sessions'] as List).isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'No sessions registered.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        );
                      } else {
                        final sessions = snapshot.data!['sessions'] as List;
                        final attendedIds = Set<int>.from(
                          (snapshot.data!['attended_sessions'] as List).map(
                            (s) => s['id'],
                          ),
                        );
                        return ExpansionTile(
                          title: Text('Count: ${sessions.length}'),
                          children:
                              sessions.map<Widget>((s) {
                                final attended = attendedIds.contains(s['id']);
                                final sessionName =
                                    '${s['workshop_title']} - ${s['date_time'] ?? ''}';
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    sessionName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          attended ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  trailing:
                                      attended
                                          ? Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 18,
                                          )
                                          : Icon(
                                            Icons.cancel,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                  subtitle: Text(
                                    attended ? 'Attended' : 'Not attended',
                                  ),
                                );
                              }).toList(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
