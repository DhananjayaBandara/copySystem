import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/app_footer.dart';

class EditSessionScreen extends StatefulWidget {
  final int sessionId;

  const EditSessionScreen({required this.sessionId, Key? key})
    : super(key: key);

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? sessionData;
  List<dynamic> trainers = [];
  Set<int> selectedTrainerIds = {};
  bool isLoading = true;

  late TextEditingController dateController;
  late TextEditingController timeController;
  late TextEditingController registrationDeadlineController;
  late TextEditingController locationController;
  late TextEditingController targetAudienceController;

  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat timeFormat = DateFormat.jm();
  final DateFormat dateTimeLocalFormat = DateFormat('yyyy-MM-ddTHH:mm');

  @override
  void initState() {
    super.initState();
    dateController = TextEditingController();
    timeController = TextEditingController();
    registrationDeadlineController = TextEditingController();
    locationController = TextEditingController();
    targetAudienceController = TextEditingController();
    _loadSessionDetails();
  }

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    registrationDeadlineController.dispose();
    locationController.dispose();
    targetAudienceController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionDetails() async {
    try {
      final session = await ApiService.getSessionById(widget.sessionId);
      final trainerList = await ApiService.getTrainers();

      DateTime? sessionDateTime =
          session['date_time'] != null
              ? DateTime.tryParse(session['date_time'])
              : null;
      DateTime? registrationDeadline =
          session['registration_deadline'] != null
              ? DateTime.tryParse(session['registration_deadline'])
              : null;

      Set<int> assignedTrainerIds = {};
      if (session['trainers'] != null) {
        assignedTrainerIds =
            session['trainers'].map<int>((t) => t['id'] as int).toSet();
      }

      dateController.text =
          sessionDateTime != null ? dateFormat.format(sessionDateTime) : '';
      timeController.text =
          sessionDateTime != null ? timeFormat.format(sessionDateTime) : '';
      registrationDeadlineController.text =
          registrationDeadline != null
              ? dateTimeLocalFormat.format(registrationDeadline)
              : '';
      locationController.text = session['location'] ?? '';
      targetAudienceController.text = session['target_audience'] ?? '';

      setState(() {
        sessionData = session;
        trainers = trainerList;
        selectedTrainerIds = assignedTrainerIds;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load session details: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    DateTime initialDate = DateTime.now();
    if (sessionData != null && sessionData!['date_time'] != null) {
      final dt = DateTime.tryParse(sessionData!['date_time']);
      if (dt != null) initialDate = dt;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    final time = _getTimeFromSession() ?? TimeOfDay.now();

    _updateDateTime(picked, time);
  }

  Future<void> _pickTime() async {
    TimeOfDay initialTime = _getTimeFromSession() ?? TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) return;

    final date = _getDateFromSession() ?? DateTime.now();

    _updateDateTime(date, picked);
  }

  Future<void> _pickRegistrationDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final deadline = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    sessionData!['registration_deadline'] = deadline.toIso8601String();
    registrationDeadlineController.text = dateTimeLocalFormat.format(deadline);
  }

  DateTime? _getDateFromSession() {
    if (sessionData != null && sessionData!['date_time'] != null) {
      return DateTime.tryParse(sessionData!['date_time']);
    }
    return null;
  }

  TimeOfDay? _getTimeFromSession() {
    final dt = _getDateFromSession();
    if (dt == null) return null;
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  void _updateDateTime(DateTime date, TimeOfDay time) {
    final updatedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    sessionData!['date_time'] = updatedDateTime.toIso8601String();
    dateController.text = dateFormat.format(updatedDateTime);
    timeController.text = timeFormat.format(updatedDateTime);
  }

  Future<void> _saveSession() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    if (sessionData == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session data is missing.')));
      return;
    }

    final workshopId = sessionData!['workshop']?['id'];
    if (workshopId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Workshop ID is missing.')));
      return;
    }

    try {
      final updateSuccess = await ApiService.updateSession(widget.sessionId, {
        'workshop_id': workshopId,
        'date_time': sessionData!['date_time'],
        'location': locationController.text.trim(),
        'registration_deadline': sessionData!['registration_deadline'],
        'target_audience': targetAudienceController.text.trim(),
      });

      final assignSuccess = await ApiService.assignTrainersToSession(
        widget.sessionId,
        selectedTrainerIds.toList(),
      );

      if (updateSuccess && assignSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session updated successfully!')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update session.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _removeTrainer(int trainerId) async {
    final success = await ApiService.removeTrainerFromSession(
      widget.sessionId,
      trainerId,
    );
    if (success) {
      setState(() {
        selectedTrainerIds.remove(trainerId);
        if (sessionData != null && sessionData!['trainers'] != null) {
          sessionData!['trainers'] =
              sessionData!['trainers']
                  .where((t) => t['id'] != trainerId)
                  .toList();
        }
      });
    }
  }

  Widget _buildFormSection({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Session Details')),
      backgroundColor: const Color(0xFFF7F8FA),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workshop title (read-only)
                Text(
                  sessionData?['workshop']?['title'] ?? 'Unknown Workshop',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                // Date & Time pickers grouped
                _buildFormSection(
                  title: 'Date & Time',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: dateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onTap: _pickDate,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please select a date'
                                      : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: timeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Time',
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onTap: _pickTime,
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please select a time'
                                      : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Registration Deadline picker
                _buildFormSection(
                  title: 'Registration Deadline',
                  child: TextFormField(
                    controller: registrationDeadlineController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Registration Deadline',
                      prefixIcon: Icon(Icons.event_busy),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onTap: _pickRegistrationDeadline,
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Please select registration deadline'
                                : null,
                  ),
                ),

                // Location input
                _buildFormSection(
                  title: 'Location',
                  child: TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Location is required'
                                : null,
                  ),
                ),

                // Target Audience input
                _buildFormSection(
                  title: 'Target Audience',
                  child: TextFormField(
                    controller: targetAudienceController,
                    decoration: const InputDecoration(
                      labelText: 'Target Audience',
                      prefixIcon: Icon(Icons.group),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Target Audience is required'
                                : null,
                  ),
                ),

                // Trainers list with selection
                _buildFormSection(
                  title: 'Assign Trainers',
                  child: Column(
                    children:
                        trainers.map((trainer) {
                          final trainerId = trainer['id'] as int;
                          final fullName = '${trainer['name']}';
                          final isSelected = selectedTrainerIds.contains(
                            trainerId,
                          );
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(fullName),
                            trailing:
                                isSelected
                                    ? IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _removeTrainer(trainerId),
                                      tooltip: 'Remove Trainer',
                                    )
                                    : IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Colors.green,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          selectedTrainerIds.add(trainerId);
                                        });
                                      },
                                      tooltip: 'Add Trainer',
                                    ),
                          );
                        }).toList(),
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _saveSession,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
