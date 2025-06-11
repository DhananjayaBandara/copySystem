import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_service.dart';

class CollectFeedbackScreen extends StatefulWidget {
  final int sessionId;
  final Map<String, dynamic> participant;

  CollectFeedbackScreen({required this.sessionId, required this.participant});

  @override
  _CollectFeedbackScreenState createState() => _CollectFeedbackScreenState();
}

class _CollectFeedbackScreenState extends State<CollectFeedbackScreen> {
  late Future<List<dynamic>> questionsFuture;
  final _formKey = GlobalKey<FormState>();
  final Map<int, dynamic> answers = {};

  @override
  void initState() {
    super.initState();
    questionsFuture = ApiService.getFeedbackQuestions(widget.sessionId);
  }

  Future<void> submitFeedback(List<dynamic> questions) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    bool allSuccess = true;
    for (var q in questions) {
      final qid = q['id'];
      final responseType = q['response_type'];
      dynamic responseValue = answers[qid];

      // For checkbox and multiple_choice, encode as JSON array string using jsonEncode
      if (responseType == 'checkbox' || responseType == 'multiple_choice') {
        responseValue =
            responseValue is List
                ? responseValue
                : (responseValue != null ? [responseValue] : []);
        responseValue = responseValue.map((e) => e.toString()).toList();
        responseValue = responseValue.isNotEmpty ? responseValue : [];
        responseValue = jsonEncode(
          responseValue,
        ); // Use jsonEncode for valid JSON array
      }

      final payload = {
        'participant': widget.participant['id'],
        'question': qid,
        'response': responseValue ?? '',
      };

      final success = await ApiService.submitFeedbackResponse(payload);
      if (!success) allSuccess = false;
    }
    if (allSuccess) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Feedback submitted!')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit some feedback responses.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Session Feedback')),
      body: FutureBuilder<List<dynamic>>(
        future: questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No feedback questions for this session.'),
            );
          } else {
            final questions = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView.builder(
                  itemCount: questions.length + 1,
                  itemBuilder: (context, idx) {
                    if (idx == questions.length) {
                      return Column(
                        children: [
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => submitFeedback(questions),
                            child: Text('Submit Feedback'),
                          ),
                        ],
                      );
                    }
                    final q = questions[idx];
                    final qid = q['id'];
                    final responseType = q['response_type'];
                    // Initialize answer if not present
                    if (!answers.containsKey(qid)) {
                      if (responseType == 'checkbox' ||
                          responseType == 'multiple_choice') {
                        answers[qid] = <String>[];
                      } else {
                        answers[qid] = '';
                      }
                    }
                    switch (responseType) {
                      case 'paragraph':
                      case 'text':
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextFormField(
                            initialValue: answers[qid],
                            decoration: InputDecoration(
                              labelText: q['question_text'],
                            ),
                            onChanged: (val) => answers[qid] = val,
                            onSaved: (val) => answers[qid] = val ?? '',
                            validator:
                                (val) =>
                                    val == null || val.isEmpty
                                        ? 'Required'
                                        : null,
                          ),
                        );
                      case 'rating':
                      case 'scale':
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: DropdownButtonFormField<String>(
                            value:
                                answers[qid]?.toString().isNotEmpty == true
                                    ? answers[qid].toString()
                                    : null,
                            decoration: InputDecoration(
                              labelText: q['question_text'],
                            ),
                            items: List.generate(
                              10,
                              (i) => DropdownMenuItem(
                                value: '${i + 1}',
                                child: Text('${i + 1}'),
                              ),
                            ),
                            onChanged: (val) => answers[qid] = val,
                            validator:
                                (val) =>
                                    val == null || val.isEmpty
                                        ? 'Required'
                                        : null,
                          ),
                        );
                      case 'checkbox':
                      case 'multiple_choice':
                        final options =
                            (q['options'] as List<dynamic>?)
                                ?.map((e) => e.toString())
                                .toList() ??
                            [];
                        final selected = List<String>.from(answers[qid] ?? []);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(q['question_text']),
                              ...options.map((option) {
                                return CheckboxListTile(
                                  title: Text(option),
                                  value: selected.contains(option),
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        selected.add(option);
                                      } else {
                                        selected.remove(option);
                                      }
                                      answers[qid] = List<String>.from(
                                        selected,
                                      );
                                    });
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      case 'yes_no':
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: DropdownButtonFormField<String>(
                            value:
                                answers[qid]?.toString().isNotEmpty == true
                                    ? answers[qid].toString()
                                    : null,
                            decoration: InputDecoration(
                              labelText: q['question_text'],
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'Yes',
                                child: Text('Yes'),
                              ),
                              DropdownMenuItem(value: 'No', child: Text('No')),
                            ],
                            onChanged: (val) => answers[qid] = val,
                            validator:
                                (val) =>
                                    val == null || val.isEmpty
                                        ? 'Required'
                                        : null,
                          ),
                        );
                      default:
                        return SizedBox.shrink();
                    }
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
