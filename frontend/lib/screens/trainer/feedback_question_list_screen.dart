import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/app_footer.dart';

class FeedbackQuestionListScreen extends StatefulWidget {
  final int sessionId;

  const FeedbackQuestionListScreen({required this.sessionId, Key? key})
    : super(key: key);

  @override
  State<FeedbackQuestionListScreen> createState() =>
      _FeedbackQuestionListScreenState();
}

class _FeedbackQuestionListScreenState
    extends State<FeedbackQuestionListScreen> {
  late Future<List<dynamic>> questions;

  @override
  void initState() {
    super.initState();
    questions = ApiService.getFeedbackQuestions(widget.sessionId);
  }

  Future<void> _refreshQuestions() async {
    setState(() {
      questions = ApiService.getFeedbackQuestions(widget.sessionId);
    });
  }

  Future<List<dynamic>> fetchResponses(int questionId) async {
    final allResponses = await ApiService.getFeedbackResponses(
      widget.sessionId,
    );
    return allResponses.where((resp) {
      final q = resp['question'];
      return (q is int && q == questionId) ||
          (q is Map && q['id'] == questionId);
    }).toList();
  }

  void showResponsesDialog(
    BuildContext context,
    Map<String, dynamic> question,
  ) async {
    final responses = await fetchResponses(question['id']);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Responses to: "${question['question_text']}"'),
            content:
                responses.isEmpty
                    ? const Text('No responses yet.')
                    : SizedBox(
                      width: double.maxFinite,
                      height: 300,
                      child: ListView.separated(
                        itemCount: responses.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final resp = responses[index];
                          final participant = resp['participant'];
                          final name =
                              participant is Map
                                  ? participant['name'] ?? 'Unknown'
                                  : 'ID: ${participant.toString()}';
                          return ListTile(
                            title: Text(resp['response'] ?? ''),
                            subtitle: Text(name),
                          );
                        },
                      ),
                    ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void showOptionsDialog(BuildContext context, List options) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Options'),
            content: Text(options.join(', ')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Questions'),
        backgroundColor: Colors.deepPurple.shade600,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshQuestions,
        child: FutureBuilder<List<dynamic>>(
          future: questions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No feedback questions.'));
            }

            final data = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final q = data[index];
                return AccessibleQuestionTile(
                  question: q,
                  onViewResponses: () => showResponsesDialog(context, q),
                  onViewOptions: () {
                    if (q['options'] != null && q['options'] is List) {
                      showOptionsDialog(context, q['options']);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}

class AccessibleQuestionTile extends StatelessWidget {
  final Map<String, dynamic> question;
  final VoidCallback onViewResponses;
  final VoidCallback onViewOptions;

  const AccessibleQuestionTile({
    required this.question,
    required this.onViewResponses,
    required this.onViewOptions,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final qText = question['question_text'] ?? 'No question';
    final qType = question['response_type'] ?? 'Unknown';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Text
            Text(
              qText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              semanticsLabel: 'Question: $qText',
            ),

            const SizedBox(height: 6),

            // Type
            Text(
              'Type: $qType',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              semanticsLabel: 'Response type: $qType',
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: onViewResponses,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Responses'),
                ),
                const SizedBox(width: 12),
                if (question['options'] != null &&
                    question['options'] is List &&
                    (question['options'] as List).isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: onViewOptions,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('View Options'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
