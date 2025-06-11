import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/app_footer.dart';

class CreateFeedbackQuestionScreen extends StatefulWidget {
  final int trainerId;
  const CreateFeedbackQuestionScreen({required this.trainerId});

  @override
  _CreateFeedbackQuestionScreenState createState() =>
      _CreateFeedbackQuestionScreenState();
}

class _CreateFeedbackQuestionScreenState
    extends State<CreateFeedbackQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  int? selectedSessionId;
  bool isSessionLocked = false;
  List<Map<String, dynamic>> questions = [];
  List<dynamic> assignedSessions = [];
  bool isLoading = true;

  final List<Map<String, String>> responseTypes = [
    {'value': 'paragraph', 'label': 'Paragraph'},
    {'value': 'checkbox', 'label': 'Checkbox'},
    {'value': 'rating', 'label': 'Rating'},
    {'value': 'text', 'label': 'Text'},
    {'value': 'multiple_choice', 'label': 'Multiple Choice'},
    {'value': 'yes_no', 'label': 'Yes/No'},
    {'value': 'scale', 'label': 'Scale'},
  ];

  @override
  void initState() {
    super.initState();
    // Check for pre-filled session from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['sessionId'] != null) {
        setState(() {
          selectedSessionId = args['sessionId'];
          isSessionLocked = args['lockSession'] == true;
        });
      }
    });
    loadAssignedSessions();
  }

  void loadAssignedSessions() async {
    final trainerDetails = await ApiService.getTrainerDetails(widget.trainerId);
    setState(() {
      assignedSessions = trainerDetails['sessions'] ?? [];
      isLoading = false;
    });
  }

  void addQuestion() {
    setState(() {
      questions.add({
        'questionText': '',
        'responseType': 'paragraph',
        'options': '',
      });
    });
  }

  void removeQuestion(int index) {
    setState(() {
      questions.removeAt(index);
    });
  }

  Future<void> submitQuestions() async {
    if (!_formKey.currentState!.validate() || selectedSessionId == null) return;
    _formKey.currentState!.save();

    bool allSuccess = true;
    for (var q in questions) {
      Map<String, dynamic> payload = {
        'session': selectedSessionId,
        'question_text': q['questionText'],
        'response_type': q['responseType'],
      };
      if (q['responseType'] == 'checkbox' ||
          q['responseType'] == 'multiple_choice') {
        payload['options'] =
            q['options']
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
      }
      final success = await ApiService.createFeedbackQuestion(payload);
      if (!success) allSuccess = false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          allSuccess
              ? '✅ Feedback questions created successfully!'
              : '⚠️ Some questions failed to create.',
        ),
        backgroundColor: allSuccess ? Colors.green : Colors.red,
      ),
    );

    if (allSuccess) Navigator.pop(context);
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget buildQuestionCard(int idx) {
    final q = questions[idx];
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '📋 Question ${idx + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () => removeQuestion(idx),
                ),
              ],
            ),
            TextFormField(
              initialValue: q['questionText'],
              decoration: _inputStyle('Question Text'),
              onSaved: (val) => q['questionText'] = val ?? '',
              validator:
                  (val) => val == null || val.isEmpty ? 'Required field' : null,
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: q['responseType'],
              decoration: _inputStyle('Response Type'),
              items:
                  responseTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type['value'],
                          child: Text(type['label']!),
                        ),
                      )
                      .toList(),
              onChanged:
                  (val) =>
                      setState(() => q['responseType'] = val ?? 'paragraph'),
            ),
            if (q['responseType'] == 'checkbox' ||
                q['responseType'] == 'multiple_choice')
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  initialValue: q['options'],
                  decoration: _inputStyle('Options (comma separated)'),
                  onSaved: (val) => q['options'] = val ?? '',
                  validator: (val) {
                    if ((val == null || val.isEmpty) &&
                        (q['responseType'] == 'checkbox' ||
                            q['responseType'] == 'multiple_choice')) {
                      return 'Options are required for this type';
                    }
                    return null;
                  },
                ),
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
        title: Text('Create Feedback Questions'),
        backgroundColor: Colors.indigo,
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: selectedSessionId,
                        decoration: _inputStyle('Select Session'),
                        items:
                            assignedSessions
                                .map(
                                  (session) => DropdownMenuItem<int>(
                                    value: session['session_id'],
                                    child: Text(
                                      '${session['workshop_title']} - ${session['date_time'].toString().split("T")[0]}',
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            isSessionLocked
                                ? null
                                : (val) =>
                                    setState(() => selectedSessionId = val),
                        validator:
                            (val) =>
                                val == null ? 'Please select a session' : null,
                        disabledHint:
                            isSessionLocked && selectedSessionId != null
                                ? Builder(
                                  builder: (context) {
                                    final session = assignedSessions.firstWhere(
                                      (s) =>
                                          s['session_id'] == selectedSessionId,
                                      orElse: () => null,
                                    );
                                    if (session != null) {
                                      return Text(
                                        '${session['workshop_title']} - ${session['date_time'].toString().split("T")[0]}',
                                      );
                                    }
                                    return const Text('Session');
                                  },
                                )
                                : null,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: addQuestion,
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Add Question',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: submitQuestions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Submit All Questions',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: questions.length,
                          itemBuilder: (context, idx) => buildQuestionCard(idx),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
