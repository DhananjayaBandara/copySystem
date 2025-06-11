import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../template/details_screen.dart';
import '../admin/session_details_screen.dart';

class TrainerDetailsScreen extends StatelessWidget {
  final int trainerId;

  TrainerDetailsScreen({required this.trainerId});

  // Function to fetch trainer details
  Future<Map<String, dynamic>> fetchTrainerDetails(int trainerId) {
    return ApiService.getTrainerDetails(trainerId);
  }

  @override
  Widget build(BuildContext context) {
    return DetailScreenTemplate(
      dynamicTitleKey: 'name',
      screenTitle: 'Trainer Details',
      fetchData: fetchTrainerDetails,
      itemId: trainerId,
      titleAtTop:
          'Trainer Information', // Default value, will be overwritten by API data
      detailItems: [
        DetailItem(
          title: 'Designation',
          icon: '0xe0c8', // Badge Icon
          subtitle: (data) => data['designation'] ?? 'N/A',
        ),
        DetailItem(
          title: 'Email',
          icon: '0xe22a', // Email Icon
          subtitle: (data) => data['email'] ?? 'N/A',
        ),
        DetailItem(
          title: 'Contact Number',
          icon: '0xe4a2', // Phone Icon
          subtitle: (data) => data['contact_number'] ?? 'N/A',
        ),
        DetailItem(
          title: 'Expertise',
          icon: '0xf0614', // Star Icon
          subtitle: (data) => data['expertise'] ?? 'N/A',
        ),
      ],
      sections: [
        Section(
          title: 'Assigned Sessions',
          builder: (data) {
            final sessions = data['sessions'] ?? [];
            return sessions.isEmpty
                ? Text(
                  'No sessions assigned.',
                  style: TextStyle(color: Colors.grey.shade600),
                )
                : Column(
                  children:
                      sessions.map<Widget>((session) {
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                '${session['session_id']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                            title: Text(
                              session['workshop_title'] ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            subtitle: Text(
                              'Date and Time: ${session['date_time']} | Location: ${session['location'] ?? 'N/A'}',
                            ),
                            onTap: () {
                              if (session['session_id'] != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => SessionDetailsScreen(
                                          sessionId: session['session_id'],
                                        ),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      }).toList(),
                );
          },
        ),
      ],
    );
  }
}
