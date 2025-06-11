import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'edit_trainer_screen.dart';
import 'create_feedback_question_screen.dart';
import 'feedback_question_list_screen.dart';
import '../admin/session_details_screen.dart';
import '../../widgets/app_footer.dart';
import '../../utils/list_utils.dart';

class TrainerDashboardScreen extends StatefulWidget {
  final int trainerId;
  const TrainerDashboardScreen({Key? key, required this.trainerId})
    : super(key: key);

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  late Future<Map<String, dynamic>> _trainerFuture;

  @override
  void initState() {
    super.initState();
    _trainerFuture = ApiService.getTrainerDetails(widget.trainerId);
  }

  void _refreshTrainer() {
    setState(() {
      _trainerFuture = ApiService.getTrainerDetails(widget.trainerId);
    });
  }

  void _editTrainer(Map<String, dynamic> trainer) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTrainerScreen(trainerId: widget.trainerId),
      ),
    );
    if (updated != null) _refreshTrainer();
  }

  void _createFeedbackQuestionsForSession(int sessionId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CreateFeedbackQuestionScreen(trainerId: widget.trainerId),
        settings: RouteSettings(
          arguments: {
            'sessionId': sessionId,
            'lockSession': true, // Pass flag to lock session field
          },
        ),
      ),
    );
  }

  void _viewFeedbackResponses(int sessionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackQuestionListScreen(sessionId: sessionId),
      ),
    );
  }

  void _viewSessionDetails(int sessionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionDetailsScreen(sessionId: sessionId),
      ),
    );
  }

  Widget _buildTrainerInfoCard(Map<String, dynamic> trainer) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trainer['name'] ?? 'Trainer',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Edit Details',
                  onPressed: () => _editTrainer(trainer),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(),
            ListTile(
              leading: Icon(Icons.badge, color: Colors.blue.shade700),
              title: Text('Designation'),
              subtitle: Text(trainer['designation'] ?? 'N/A'),
            ),
            ListTile(
              leading: Icon(Icons.email, color: Colors.blue.shade700),
              title: Text('Email'),
              subtitle: Text(trainer['email'] ?? 'N/A'),
            ),
            ListTile(
              leading: Icon(Icons.phone, color: Colors.blue.shade700),
              title: Text('Contact Number'),
              subtitle: Text(trainer['contact_number'] ?? 'N/A'),
            ),
            ListTile(
              leading: Icon(Icons.star, color: Colors.blue.shade700),
              title: Text('Expertise'),
              subtitle: Text(trainer['expertise'] ?? 'N/A'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer Details'),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshTrainer,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _trainerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Failed to load trainer details.'));
          }
          final trainer = snapshot.data!;
          final sessions = trainer['sessions'] as List<dynamic>? ?? [];
          final indexedSessions = indexListElements(
            sessions,
            valueKey: 'session',
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrainerInfoCard(trainer),
                const SizedBox(height: 24),
                Text(
                  'Assigned Sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
                const SizedBox(height: 10),
                indexedSessions.isEmpty
                    ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'No sessions assigned.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                    : Column(
                      children: List.generate(indexedSessions.length, (idx) {
                        final session = indexedSessions[idx]['session'];
                        final sessionIndex = indexedSessions[idx]['index'];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  sessionIndex.toString(),
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (session['date_time'] != null)
                                    Text(
                                      'Date: ${session['date_time'].toString().split("T")[0]}',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  if (session['location'] != null)
                                    Text(
                                      'Location: ${session['location']}',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                ],
                              ),
                              onTap:
                                  () => _viewSessionDetails(
                                    session['session_id'],
                                  ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.add_comment, size: 18),
                                    label: Text('Create Feedback'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(fontSize: 13),
                                    ),
                                    onPressed:
                                        () =>
                                            _createFeedbackQuestionsForSession(
                                              session['session_id'],
                                            ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: Icon(
                                      Icons.forum,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    label: Text(
                                      'Responses',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.blue.shade300,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(fontSize: 13),
                                    ),
                                    onPressed:
                                        () => _viewFeedbackResponses(
                                          session['session_id'],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
