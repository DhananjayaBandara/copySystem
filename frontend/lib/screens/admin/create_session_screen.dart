import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/dialog_box.dart'; // Your dialog box for success/error dialogs
import 'edit_session_screen.dart';
import '../../template/create_screen.dart'; // Your custom form screen template

class CreateSessionScreen extends StatefulWidget {
  @override
  _CreateSessionScreenState createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  List<dynamic> workshops = [];
  bool isLoading = true;

  // Initial form data for the session
  Map<String, dynamic> initialData = {
    'workshop_id': null,
    'date': '',
    'time': '',
    'location': '',
    'registration_deadline': '',
    'target_audience': '',
  };

  @override
  void initState() {
    super.initState();
    loadWorkshops();
  }

  Future<void> loadWorkshops() async {
    final data = await ApiService.getWorkshops();
    setState(() {
      workshops = data;
      isLoading = false;
    });
  }

  Future<void> handleSubmit(Map<String, dynamic> formData) async {
    // Combine date and time into a single ISO8601 datetime string
    try {
      if (formData['date'] == null || formData['date'].isEmpty) {
        throw {
          'date': ['Session Date is required.'],
        };
      }
      if (formData['time'] == null || formData['time'].isEmpty) {
        throw {
          'time': ['Session Time is required.'],
        };
      }

      final date = DateTime.tryParse(formData['date']);
      final time = DateTime.tryParse(formData['time']);

      if (date == null || time == null) {
        throw {
          'datetime': ['Invalid date or time format.'],
        };
      }

      final sessionDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      final payload = {
        'workshop_id': formData['workshop_id'],
        'date_time': sessionDateTime.toIso8601String(),
        'location': formData['location'],
        'registration_deadline': formData['registration_deadline'],
        'target_audience': formData['target_audience'],
      };

      final success = await ApiService.createSession(payload);

      if (!success) {
        throw {
          'Error': ['Failed to create session'],
        };
      }

      // After creation, get sessions, then navigate to EditSessionScreen for last session
      final sessions = await ApiService.getSessions();
      final newSession = sessions.last;

      await CustomDialog.showSuccess(
        context,
        title: 'Session Created',
        message: 'The session has been successfully created.',
        onOkPressed: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EditSessionScreen(sessionId: newSession['id']),
            ),
          );
        },
      );
    } catch (errors) {
      await CustomDialog.showError(
        context,
        title: 'Failed to Create Session',
        errors:
            errors is Map<String, dynamic>
                ? errors
                : {
                  'Error': ['Unexpected error occurred.'],
                },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Pre-fill workshop_id if passed as argument
    if (args != null && args.containsKey('workshop_id')) {
      initialData['workshop_id'] = args['workshop_id'];
      initialData['workshop_title'] = args['workshop_title'] ?? '';
    }

    final bool isWorkshopLocked = initialData['workshop_id'] != null;

    // Define fields config for the form
    final List<FormFieldConfig> fields = [
      // Workshop dropdown or read-only field
      if (isWorkshopLocked)
        FormFieldConfig(
          label: 'Workshop Title',
          icon: Icons.work,
          keyName: 'workshop_title',
          isRequired: true,
          fieldType: FieldType.custom,
          customBuilder: (context, formData, onChanged) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextFormField(
                initialValue: initialData['workshop_title'] ?? '',
                decoration: InputDecoration(
                  labelText: 'Workshop Title',
                  prefixIcon: Icon(Icons.work),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                enabled: false,
              ),
            );
          },
        )
      else
        FormFieldConfig(
          label: 'Select Workshop',
          icon: Icons.work,
          keyName: 'workshop_id',
          isRequired: true,
          fieldType: FieldType.custom,
          customBuilder: (context, formData, onChanged) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: DropdownButtonFormField<int>(
                value: formData['workshop_id'],
                decoration: InputDecoration(
                  labelText: 'Select Workshop',
                  prefixIcon: Icon(Icons.work),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                items:
                    workshops
                        .map<DropdownMenuItem<int>>(
                          (workshop) => DropdownMenuItem<int>(
                            value: workshop['id'],
                            child: Text(workshop['title']),
                          ),
                        )
                        .toList(),
                onChanged: (val) => onChanged(val),
                validator:
                    (value) =>
                        value == null ? 'Please select a workshop' : null,
              ),
            );
          },
        ),
      // Date picker for Session Date
      FormFieldConfig(
        label: 'Session Date',
        icon: Icons.calendar_today,
        keyName: 'date',
        isRequired: true,
        fieldType: FieldType.date,
      ),

      // Time picker for Session Time
      FormFieldConfig(
        label: 'Session Time',
        icon: Icons.access_time,
        keyName: 'time',
        isRequired: true,
        fieldType: FieldType.time,
      ),

      // Location text input
      FormFieldConfig(
        label: 'Location',
        icon: Icons.location_on,
        keyName: 'location',
        isRequired: true,
        fieldType: FieldType.text,
      ),

      // Registration Deadline (date-time picker)
      FormFieldConfig(
        label: 'Registration Deadline',
        icon: Icons.timer_off,
        keyName: 'registration_deadline',
        isRequired: true,
        fieldType: FieldType.dateTime,
      ),

      // Target Audience text input
      FormFieldConfig(
        label: 'Target Audience',
        icon: Icons.group,
        keyName: 'target_audience',
        isRequired: true,
        fieldType: FieldType.text,
      ),
    ];

    return isLoading
        ? Scaffold(
          appBar: AppBar(
            title: const Text('Create Session'),
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade700, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        )
        : CustomFormScreen(
          title: 'Create Session',
          icon: Icons.event_note,
          initialData: initialData,
          fields: fields,
          onSubmit: handleSubmit,
          submitButtonText: 'Create Session',
        );
  }
}
